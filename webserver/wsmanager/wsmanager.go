package wsmanager

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/gobwas/ws"
	"github.com/gobwas/ws/wsutil"
)

type ConnectionManager struct {
	mu            sync.Mutex
	clients       map[*Connection]bool
	subscriptions map[string]map[*Connection]bool
	broadcast     chan Message
	userConnMap   map[any][]*Connection // Mapping from user ID to connections
}

var instance *ConnectionManager
var once sync.Once

func NewConnectionManager() *ConnectionManager {
	once.Do(func() {
		instance = &ConnectionManager{
			clients:       make(map[*Connection]bool),
			subscriptions: make(map[string]map[*Connection]bool),
			broadcast:     make(chan Message),
			userConnMap:   make(map[any][]*Connection),
		}
		// Optionally start handling broadcasts
		go instance.handleBroadcasts()
	})
	return instance
}

func (cm *ConnectionManager) AddClient(conn *Connection, userID any) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.clients[conn] = true
	if userID != "" {
		cm.userConnMap[userID] = append(cm.userConnMap[userID], conn)
	}
	log.Println("Client added:", conn)
}

func (cm *ConnectionManager) RemoveClient(conn *Connection, userID any) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	delete(cm.clients, conn)
	if userID != "" {
		conns := cm.userConnMap[userID]
		for i, c := range conns {
			if c == conn {
				cm.userConnMap[userID] = append(conns[:i], conns[i+1:]...)
				break
			}
		}
		if len(cm.userConnMap[userID]) == 0 {
			delete(cm.userConnMap, userID)
		}
	}
	for topic := range cm.subscriptions {
		delete(cm.subscriptions[topic], conn)
		if len(cm.subscriptions[topic]) == 0 {
			delete(cm.subscriptions, topic)
		}
	}
	log.Println("Client removed:", conn)
}

func (cm *ConnectionManager) Subscribe(conn *Connection, topic string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	if cm.subscriptions[topic] == nil {
		cm.subscriptions[topic] = make(map[*Connection]bool)
	}
	cm.subscriptions[topic][conn] = true
	log.Printf("Client subscribed to topic %s: %v", topic, conn)
}

func (cm *ConnectionManager) Broadcast(msg Message, sender *Connection) {
	msg.Sender = sender
	log.Printf("Broadcasting message: %v", msg)
	cm.broadcast <- msg
}

func (cm *ConnectionManager) handleBroadcasts() {
	for {
		msg := <-cm.broadcast
		cm.mu.Lock()
		topicPayload := struct {
			Topic   string          `json:"topic"`
			Payload json.RawMessage `json:"payload"`
		}{}
		if err := json.Unmarshal(msg.Payload, &topicPayload); err != nil {
			log.Printf("Error unmarshaling broadcast payload: %v", err)
			cm.mu.Unlock()
			continue
		}
		subscribers, exists := cm.subscriptions[topicPayload.Topic]
		if !exists {
			log.Printf("No subscribers for topic %s", topicPayload.Topic)
		} else {
			log.Printf("Found %d subscribers for topic %s", len(subscribers), topicPayload.Topic)
		}
		for client := range subscribers {
			if client == msg.Sender {
				continue // Skip the sender
			}
			go func(client *Connection) {
				client.mu.Lock()
				defer client.mu.Unlock()
				err := wsutil.WriteServerMessage(client.Conn, ws.OpText, topicPayload.Payload)
				if err != nil {
					log.Printf("Error sending message to client: %v", err)
					client.Conn.Close()
					// Depending on your policy, you might want to retry, log, or handle the error differently
				} else {
					log.Printf("Message sent to client: %v", client)
				}
			}(client)
		}
		cm.mu.Unlock()
	}
}

// GetConnectionsForUser retrieves all connections for a given user
func (cm *ConnectionManager) GetConnectionsForUser(userID any) []*Connection {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	return cm.userConnMap[userID]
}
