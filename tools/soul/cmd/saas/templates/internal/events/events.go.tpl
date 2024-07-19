package events

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// NextFunc is the function called when an event is emitted.
type NextFunc func(context.Context, any) error

var subject *Subject

// Next emits an event to the given topic using the default subject.
func Next(topic string, value any) error {
	return subject.Next(topic, value)
}

// Subscribe subscribes a NextFunc to the given topic using the default subject.
// A Subscription is returned that can be used to unsubscribe from the topic.
func Subscribe(topic string, next NextFunc) Subscription {
	return subject.Subscribe(topic, next)
}

// Unsubscribe unsubscribes the given Subscription from its topic using the default subject.
func Unsubscribe(sub Subscription) {
	subject.Unsubscribe(sub)
}

// Complete stops the event stream, cleaning up its resources using the default subject.
func Complete() {
	subject.Complete()
}

type event struct {
	topic   string
	message any
}

// Subscription represents a handler subscribed to a specific topic.
type Subscription struct {
	Topic     string
	CreatedAt int64
	Next      NextFunc
}

type Subject struct {
	mu          sync.RWMutex
	subscribers map[string][]Subscription
	events      chan event
	complete    chan struct{}
}

// NewSubject creates a new Subject.
func NewSubject() *Subject {
	s := &Subject{
		subscribers: make(map[string][]Subscription),
		events:      make(chan event, 128),
		complete:    make(chan struct{}),
	}
	go s.start()
	return s
}

func (s *Subject) start() {
	for {
		select {
		case <-s.complete:
			return
		case evt := <-s.events:
			s.mu.RLock()
			if handlers, ok := s.subscribers[evt.topic]; ok {
				for _, sub := range handlers {
					go func(sub Subscription, evt event) {
						ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
						defer cancel()
						err := sub.Next(ctx, evt.message)
						if err != nil {
							// Handle the error (logging, retry, etc.)
						}
					}(sub, evt)
				}
			}
			s.mu.RUnlock()
		}
	}
}

func (s *Subject) Complete() {
	close(s.complete)
	close(s.events)
}

func (s *Subject) Next(topic string, value any) error {
	select {
	case s.events <- event{
		topic:   topic,
		message: value,
	}:
		return nil
	case <-time.After(1 * time.Second):
		return fmt.Errorf("failed to emit event: %v", value)
	}
}

func (s *Subject) Subscribe(topic string, next NextFunc) Subscription {
	sub := Subscription{
		CreatedAt: time.Now().UnixNano(),
		Topic:     topic,
		Next:      next,
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.subscribers[topic]; !ok {
		s.subscribers[topic] = []Subscription{}
	}

	s.subscribers[topic] = append(s.subscribers[topic], sub)

	return sub
}

func (s *Subject) Unsubscribe(sub Subscription) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if handlers, ok := s.subscribers[sub.Topic]; ok {
		for i, handler := range handlers {
			if handler.CreatedAt == sub.CreatedAt {
				s.subscribers[sub.Topic] = append(handlers[:i], handlers[i+1:]...)
				break
			}
		}
		if len(s.subscribers[sub.Topic]) == 0 {
			delete(s.subscribers, sub.Topic)
		}
	}
}

func init() {
	subject = NewSubject()
}

// ReplaySubject caches the last N events and re-emits them to new subscribers.
type ReplaySubject struct {
	Subject
	cacheSize int
	cache     []event
}

// NewReplaySubject creates a new ReplaySubject with a specified cache size.
func NewReplaySubject(cacheSize int) *ReplaySubject {
	rs := &ReplaySubject{
		Subject:   *NewSubject(),
		cacheSize: cacheSize,
		cache:     make([]event, 0, cacheSize),
	}
	return rs
}

func (rs *ReplaySubject) Next(topic string, value any) error {
	rs.mu.Lock()
	defer rs.mu.Unlock()

	evt := event{topic: topic, message: value}

	// Add to cache
	if len(rs.cache) == rs.cacheSize {
		rs.cache = rs.cache[1:]
	}
	rs.cache = append(rs.cache, evt)

	return rs.Subject.Next(topic, value)
}

func (rs *ReplaySubject) Subscribe(topic string, next NextFunc) Subscription {
	rs.mu.RLock()
	defer rs.mu.RUnlock()

	sub := rs.Subject.Subscribe(topic, next)

	// Replay cached events
	for _, evt := range rs.cache {
		if evt.topic == topic {
			go func(evt event) {
				ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
				defer cancel()
				err := next(ctx, evt.message)
				if err != nil {
					// Handle the error (logging, retry, etc.)
				}
			}(evt)
		}
	}

	return sub
}
