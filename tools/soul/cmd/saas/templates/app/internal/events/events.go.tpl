package events

import (
	"context"
	"fmt"
	"net"
	"sync"
	"time"
)

// NextFunc is the function called when an event is emitted.
// It can optionally receive a net.Conn as its last parameter.
type NextFunc interface{}

var subject *Subject

// Next emits an event to the given topic using the default subject.
// If a connection is provided, the event will only be delivered to that specific client.
func Next(topic string, value any, conn ...net.Conn) error {
	return subject.Next(topic, value, conn...)
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
	conn    net.Conn
}

// Subscription represents a handler subscribed to a specific topic.
type Subscription struct {
	Topic     string
	CreatedAt int64
	Next      NextFunc
	ID        string // Add a unique identifier
}

type Subject struct {
	mu          sync.RWMutex
	subscribers map[string]map[string]Subscription // Change to map of maps for efficient lookup
	events      chan event
	complete    chan struct{}
}

// NewSubject creates a new Subject.
func NewSubject() *Subject {
	s := &Subject{
		subscribers: make(map[string]map[string]Subscription),
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
						switch fn := sub.Next.(type) {
						case func(context.Context, any) error:
							err := fn(ctx, evt.message)
							if err != nil {
								// Handle the error (logging, retry, etc.)
								fmt.Printf("Error processing event for topic %s: %v\n", evt.topic, err)
							}
						case func(context.Context, any, net.Conn) error:
							err := fn(ctx, evt.message, evt.conn)
							if err != nil {
								// Handle the error (logging, retry, etc.)
								fmt.Printf("Error processing event with connection for topic %s: %v\n", evt.topic, err)
							}
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

func (s *Subject) Next(topic string, value any, conn ...net.Conn) error {
	var connection net.Conn
	if len(conn) > 0 {
		connection = conn[0]
	}
	select {
	case s.events <- event{
		topic:   topic,
		message: value,
		conn:    connection,
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
		ID:        fmt.Sprintf("%s-%d", topic, time.Now().UnixNano()), // Generate a unique ID
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.subscribers[topic]; !ok {
		s.subscribers[topic] = make(map[string]Subscription)
	}

	s.subscribers[topic][sub.ID] = sub

	fmt.Printf("Subscribed to topic %s with ID %s\n", topic, sub.ID)

	return sub
}

func (s *Subject) Unsubscribe(sub Subscription) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if topicSubs, ok := s.subscribers[sub.Topic]; ok {
		delete(topicSubs, sub.ID)
		if len(topicSubs) == 0 {
			delete(s.subscribers, sub.Topic)
		}
		fmt.Printf("Unsubscribed from topic %s with ID %s\n", sub.Topic, sub.ID)
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
	sent      map[string]map[string]bool // Track sent events per subscriber
}

// NewReplaySubject creates a new ReplaySubject with a specified cache size.
func NewReplaySubject(cacheSize int) *ReplaySubject {
	rs := &ReplaySubject{
		Subject:   *NewSubject(),
		cacheSize: cacheSize,
		cache:     make([]event, 0, cacheSize),
		sent:      make(map[string]map[string]bool),
	}
	return rs
}

func (rs *ReplaySubject) Next(topic string, value any, conn ...net.Conn) error {
	rs.mu.Lock()
	defer rs.mu.Unlock()

	var connection net.Conn
	if len(conn) > 0 {
		connection = conn[0]
	}

	evt := event{topic: topic, message: value, conn: connection}

	// Add to cache
	if len(rs.cache) == rs.cacheSize {
		rs.cache = rs.cache[1:]
	}
	rs.cache = append(rs.cache, evt)

	fmt.Printf("Event added to cache for topic %s\n", topic)

	return rs.Subject.Next(topic, value, connection)
}

func (rs *ReplaySubject) Subscribe(topic string, next NextFunc, replayEvents bool) Subscription {
	rs.mu.Lock()
	defer rs.mu.Unlock()

	sub := rs.Subject.Subscribe(topic, next)

	if replayEvents {
		rs.sent[sub.ID] = make(map[string]bool)
		// Replay cached events
		for _, evt := range rs.cache {
			if evt.topic == topic {
				eventID := fmt.Sprintf("%s-%v", evt.topic, evt.message)
				if !rs.sent[sub.ID][eventID] {
					go rs.processEvent(sub, evt)
					rs.sent[sub.ID][eventID] = true
					fmt.Printf("Replayed event for topic %s to subscriber %s\n", topic, sub.ID)
				}
			}
		}
	}

	return sub
}

func (rs *ReplaySubject) processEvent(sub Subscription, evt event) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	switch fn := sub.Next.(type) {
	case func(context.Context, any) error:
		err := fn(ctx, evt.message)
		if err != nil {
			// Handle the error (logging, retry, etc.)
			fmt.Printf("Error processing event for topic %s: %v\n", evt.topic, err)
		}
	case func(context.Context, any, net.Conn) error:
		err := fn(ctx, evt.message, evt.conn)
		if err != nil {
			// Handle the error (logging, retry, etc.)
			fmt.Printf("Error processing event with connection for topic %s: %v\n", evt.topic, err)
		}
	}
}
