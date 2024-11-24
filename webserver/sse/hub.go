package sse

import (
	"fmt"
	"sync"
)

// EventHub manages per-path and per-client event delivery
type EventHub struct {
	mu          sync.RWMutex
	subscribers map[string]map[int64]chan interface{}
}

// NewEventHub initializes a new EventHub
func NewEventHub() *EventHub {
	return &EventHub{
		subscribers: make(map[string]map[int64]chan interface{}),
	}
}

// Subscribe adds a new subscriber for a specific path and client
func (hub *EventHub) Subscribe(path string, clientID int64) chan interface{} {
	hub.mu.Lock()
	defer hub.mu.Unlock()

	if _, ok := hub.subscribers[path]; !ok {
		hub.subscribers[path] = make(map[int64]chan interface{})
	}

	ch := make(chan interface{}, 10) // Buffered channel for async delivery
	hub.subscribers[path][clientID] = ch
	return ch
}

// Unsubscribe removes a subscriber for a specific path and client
func (hub *EventHub) Unsubscribe(path string, clientID int64) {
	hub.mu.Lock()
	defer hub.mu.Unlock()

	if clients, ok := hub.subscribers[path]; ok {
		if ch, ok := clients[clientID]; ok {
			close(ch)
			delete(clients, clientID)
		}
		// Clean up the path if no more subscribers exist
		if len(clients) == 0 {
			delete(hub.subscribers, path)
		}
	}
}

// Broadcast sends an event to a specific client on a specific path
func (hub *EventHub) Broadcast(path string, clientID int64, event interface{}) {
	hub.mu.RLock()
	defer hub.mu.RUnlock()

	if clients, ok := hub.subscribers[path]; ok {
		if ch, ok := clients[clientID]; ok {
			select {
			case ch <- event:
			default: // Drop event if the channel is full
				fmt.Printf("Dropping event for client %d on path %s: channel full\n", clientID, path)
			}
		}
	}
}

// BroadcastPath sends an event to all clients subscribed to a specific path
func (hub *EventHub) BroadcastPath(path string, event interface{}) {
	hub.mu.RLock()
	defer hub.mu.RUnlock()

	if clients, ok := hub.subscribers[path]; ok {
		for clientID, ch := range clients {
			select {
			case ch <- event:
			default: // Drop event if the channel is full
				fmt.Printf("Dropping event for client %d on path %s: channel full\n", clientID, path)
			}
		}
	}
}

// BroadcastAll sends an event to all clients across all paths
func (hub *EventHub) BroadcastAll(event interface{}) {
	hub.mu.RLock()
	defer hub.mu.RUnlock()

	for path, clients := range hub.subscribers {
		for clientID, ch := range clients {
			select {
			case ch <- event:
			default: // Drop event if the channel is full
				fmt.Printf("Dropping event for client %d on path %s: channel full\n", clientID, path)
			}
		}
	}
}
