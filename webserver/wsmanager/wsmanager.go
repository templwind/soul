package wsmanager

import (
	"encoding/json"
	"log"
	"net"
	"sync"

	"github.com/gobwas/ws"
	"github.com/gobwas/ws/wsutil"
)

type Connection struct {
	conn net.Conn
	mu   sync.Mutex
}

type ConnectionManager struct {
	mu            sync.Mutex
	clients       map[*Connection]bool
	subscriptions map[string]map[*Connection]bool
	broadcast     chan Message
}

type Message struct {
	Topic   string          `json:"topic"`
	Payload json.RawMessage `json:"payload"`
	Sender  *Connection     `json:"-"`
}

var instance *ConnectionManager
var once sync.Once

func NewConnectionManager() *ConnectionManager {
	once.Do(func() {
		instance = &ConnectionManager{
			clients:       make(map[*Connection]bool),
			subscriptions: make(map[string]map[*Connection]bool),
			broadcast:     make(chan Message),
		}
		go instance.handleBroadcasts()
	})
	return instance
}

func NewConnection(conn net.Conn) *Connection {
	return &Connection{
		conn: conn,
	}
}

func (cm *ConnectionManager) AddClient(conn *Connection) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.clients[conn] = true
	log.Printf("Client added: %v", conn)
}

func (cm *ConnectionManager) RemoveClient(conn *Connection) {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	delete(cm.clients, conn)
	for topic := range cm.subscriptions {
		delete(cm.subscriptions[topic], conn)
		if len(cm.subscriptions[topic]) == 0 {
			delete(cm.subscriptions, topic)
		}
	}
	log.Printf("Client removed: %v", conn)
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

func (cm *ConnectionManager) Broadcast(msg Message) {
	log.Printf("Broadcasting message: %v", msg)
	cm.broadcast <- msg
}

func (cm *ConnectionManager) handleBroadcasts() {
	for {
		msg := <-cm.broadcast
		cm.mu.Lock()
		subscribers, exists := cm.subscriptions[msg.Topic]
		if !exists {
			log.Printf("No subscribers for topic %s", msg.Topic)
		} else {
			log.Printf("Found %d subscribers for topic %s", len(subscribers), msg.Topic)
		}
		for client := range subscribers {
			if client == msg.Sender {
				continue // Skip the sender
			}
			go func(client *Connection) {
				client.mu.Lock()
				defer client.mu.Unlock()
				err := wsutil.WriteServerMessage(client.conn, ws.OpText, msg.Payload)
				if err != nil {
					log.Printf("Error sending message to client: %v", err)
					client.conn.Close()
				} else {
					log.Printf("Message sent to client: %v", client)
				}
			}(client)
		}
		cm.mu.Unlock()
	}
}
