package pubsub

import (
	"encoding/json"
	"log"
	"time"
)

// Broker is the interface that wraps the methods for a message broker
type Broker interface {
	Publish(subject string, message []byte, msgID ...string) error
	Subscribe(subject string, group string, handler func([]byte) ([]byte, error)) error
	CreateStream(streamName, subject string, dedupWindow time.Duration) error
}

// Marshal marshals the given value to a JSON byte slice
func Marshal(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		log.Println(err)
	}
	return b
}
