package wsmanager

import (
	"context"
	"encoding/json"
	"sync"

	"github.com/gobwas/ws"
	"github.com/gobwas/ws/wsutil"
	"github.com/zeromicro/go-zero/core/logx"
)

type ConnectionManager struct {
	mu            sync.Mutex
	clients       map[*Connection]bool
	subscriptions map[any]map[*Connection]bool
	broadcast     chan Message
	userConnMap   map[any][]*Connection // Mapping from user ID to connections
	debug         bool                  // Add debug flag
}

var instance *ConnectionManager
var once sync.Once

func NewConnectionManager() *ConnectionManager {
	once.Do(func() {
		instance = &ConnectionManager{
			clients:       make(map[*Connection]bool),
			subscriptions: make(map[any]map[*Connection]bool),
			broadcast:     make(chan Message),
			userConnMap:   make(map[any][]*Connection),
			debug:         false, // Default to false
		}
		// Optionally start handling broadcasts
		go instance.handleBroadcasts()
	})
	return instance
}

// SetDebug enables or disables debug logging
func (cm *ConnectionManager) SetDebug(enabled bool) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.debug = enabled
}

// debugLog logs messages only when debug mode is enabled
func (cm *ConnectionManager) debugLog(msg string, fields ...logx.LogField) {
	if cm.debug {
		logx.WithContext(context.Background()).Infow(msg, fields...)
	}
}

func (cm *ConnectionManager) AddClient(conn *Connection, userID any) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.clients[conn] = true
	if userID != "" {
		cm.userConnMap[userID] = append(cm.userConnMap[userID], conn)
	}
	cm.debugLog("Client added", logx.Field("connection", conn), logx.Field("userID", userID))
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
	cm.debugLog("Client removed", logx.Field("connection", conn))
}

func (cm *ConnectionManager) Subscribe(conn *Connection, topic string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	if cm.subscriptions[topic] == nil {
		cm.subscriptions[topic] = make(map[*Connection]bool)
	}
	cm.subscriptions[topic][conn] = true
	cm.debugLog("Client subscribed to topic", logx.Field("topic", topic), logx.Field("connection", conn))
}

func (cm *ConnectionManager) Unsubscribe(conn *Connection, topic string) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	delete(cm.subscriptions[topic], conn)
	if len(cm.subscriptions[topic]) == 0 {
		delete(cm.subscriptions, topic)
	}
	cm.debugLog("Client unsubscribed from topic", logx.Field("topic", topic), logx.Field("connection", conn))
}

func (cm *ConnectionManager) Broadcast(msg Message, sender *Connection) {
	msg.Sender = sender
	cm.debugLog("Broadcasting message",
		logx.Field("message", msg),
		logx.Field("sender", sender))
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
			logx.Error("Error unmarshaling broadcast payload", logx.Field("error", err))
			cm.mu.Unlock()
			continue
		}
		subscribers, exists := cm.subscriptions[topicPayload.Topic]
		if !exists {
			cm.debugLog("No subscribers found", logx.Field("topic", topicPayload.Topic))
		} else {
			cm.debugLog("Found subscribers",
				logx.Field("topic", topicPayload.Topic),
				logx.Field("count", len(subscribers)))
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
					logx.Error("Error sending message to client", logx.Field("error", err))
					client.Conn.Close()
					// Depending on your policy, you might want to retry, log, or handle the error differently
				} else {
					logx.Info("Message sent to client", logx.Field("client", client))
				}
			}(client)
		}
		cm.mu.Unlock()
	}
}

// GetConnectionsForUser retrieves all active connections for a given user ID.
func (cm *ConnectionManager) GetConnectionsForUser(userID any) []*Connection {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	return cm.userConnMap[userID]
}

// GetSubscribers retrieves all connections subscribed to a given topic.
func (cm *ConnectionManager) GetSubscribers(topic any) map[*Connection]bool {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	if subs, exists := cm.subscriptions[topic]; exists {
		return subs
	}
	return nil
}
