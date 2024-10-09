package pubsub

import (
	"encoding/json"
	"log"
	"time"
)

type Broker interface {
	Publish(subject string, message []byte, msgID ...string) error
	Subscribe(subject string, group string, handler func([]byte) ([]byte, error)) error
	CreateStream(streamName, subject string, dedupWindow time.Duration) error
}

func Marshal(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		log.Println(err)
	}
	return b
}
