package events

import (
	"log"
	"time"
)

// NoOpBroker is a no-op implementation of the pubsub.Broker interface for when NATS is not available
type NoOpBroker struct{}

func (b *NoOpBroker) Publish(subject string, message []byte, msgID ...string) error {
	log.Printf("NoOpBroker: Would publish to subject %s", subject)
	return nil
}

func (b *NoOpBroker) Subscribe(subject string, group string, handler func([]byte) ([]byte, error)) error {
	log.Printf("NoOpBroker: Would subscribe to subject %s with group %s", subject, group)
	return nil
}

func (b *NoOpBroker) CreateStream(streamName, subject string, dedupWindow time.Duration) error {
	log.Printf("NoOpBroker: Would create stream %s for subject %s with dedup window %v", streamName, subject, dedupWindow)
	return nil
}
