package wsmanager

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"

	"github.com/gobwas/ws"
	"github.com/gobwas/ws/wsutil"
	"github.com/google/uuid"
)

var managers = make(map[string]*ConnectionManager)
var mu sync.RWMutex

func AddManager(manager *ConnectionManager, name string) {
	mu.Lock()
	defer mu.Unlock()
	if _, ok := managers[name]; !ok {
		managers[name] = manager
	}
}

func GetManager(name string) *ConnectionManager {
	mu.RLock()
	defer mu.RUnlock()
	return managers[name]
}

// RemoveManager removes a manager from the global managers map.
func RemoveManager(name string) {
	mu.Lock()
	defer mu.Unlock()
	if manager, exists := managers[name]; exists {
		for conn := range manager.clients {
			manager.RemoveClient(conn, nil)
		}
		delete(managers, name)
	}
}

// SendEvent sends an event with the given topic and payload to all users subscribed to that topic.
func SendEvent(managerName string, topic string, payload interface{}) error {
	manager := GetManager(managerName)
	if manager == nil {
		return fmt.Errorf("manager not found")
	}

	// Marshal the payload to JSON
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		log.Printf("Error marshalling payload for topic %s: %v", topic, err)
		return err
	}

	// Create a message struct
	msg := Message{
		Topic:   topic,
		Payload: json.RawMessage(payloadBytes),
		ID:      uuid.New().String(),
	}

	// Marshal the message
	out, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Error marshalling message for topic %s: %v", topic, err)
		return err
	}

	// Broadcast the event to all subscribed clients
	for conn := range manager.GetSubscribers(topic) {
		err := wsutil.WriteServerMessage(conn.Conn, ws.OpText, out)
		if err != nil {
			log.Printf("Failed to send event to user %s: %v", conn.Conn, err)
			// Optionally, handle the error (e.g., remove the connection)
		}
	}

	return nil
}

// SendEventToUser sends an event with the given topic and payload to a specific user.
func SendEventToUser(managerName string, userID any, topic string, payload interface{}) error {
	manager := GetManager(managerName)
	if manager == nil {
		return fmt.Errorf("manager not found")
	}

	// Retrieve the user's connections
	connections := manager.GetConnectionsForUser(userID)
	if len(connections) == 0 {
		log.Printf("No active connections for user %s", userID)
		return nil // Optionally, return an error if needed
	}

	// Marshal the payload to JSON
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		log.Printf("Error marshalling payload for user %s: %v", userID, err)
		return err
	}

	// Create a message struct
	msg := Message{
		Topic:   topic,
		Payload: json.RawMessage(payloadBytes),
		ID:      uuid.New().String(),
	}

	// Marshal the message
	out, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Error marshalling message for user %s: %v", userID, err)
		return err
	}

	// Send the event to each connection of the user
	for _, conn := range connections {
		err := wsutil.WriteServerMessage(conn.Conn, ws.OpText, out)
		if err != nil {
			log.Printf("Failed to send event to user %s: %v", userID, err)
			// Optionally, handle the error (e.g., remove the connection)
		}
	}

	return nil
}
