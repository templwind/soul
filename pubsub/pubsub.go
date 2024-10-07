package pubsub

import (
	"time"
)

type Broker interface {
	Publish(subject string, message []byte, msgID ...string) error
	Subscribe(subject string, handler func([]byte) ([]byte, error)) error
	CreateStream(streamName, subject string, dedupWindow time.Duration) error
}