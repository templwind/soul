package pubsub

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/nats-io/nats.go"
	"github.com/redis/go-redis/v9"
)

// NATSBroker defines the structure of the NATS broker with Redis for deduplication
type NATSBroker struct {
	conn  *nats.Conn
	js    nats.JetStreamContext
	redis *redis.Client
	ctx   context.Context
}

// NewNATSBroker initializes the NATS broker and the Redis client
func NewNATSBroker(url string, redisAddr string) (*NATSBroker, error) {
	nc, err := nats.Connect(url)
	if err != nil {
		return nil, err
	}

	js, err := nc.JetStream()
	if err != nil {
		return nil, err
	}

	// Initialize Redis client
	rdb := redis.NewClient(&redis.Options{
		Addr: redisAddr,
	})

	ctx := context.Background()

	return &NATSBroker{
		conn:  nc,
		js:    js,
		redis: rdb,
		ctx:   ctx,
	}, nil
}

// CreateStream creates a new stream with a deduplication window
func (n *NATSBroker) CreateStream(streamName, subject string, dedupWindow time.Duration) error {
	_, err := n.js.AddStream(&nats.StreamConfig{
		Name:       streamName,
		Subjects:   []string{subject},
		Duplicates: dedupWindow, // Set the deduplication window
	})
	return err
}

// Publish publishes a message to a NATS JetStream subject using the provided msgID for deduplication
func (n *NATSBroker) Publish(subject string, message []byte, msgID ...string) error {
	var messageID string
	if len(msgID) == 0 {
		// Generate a unique message ID if none is provided
		messageID = uuid.New().String()
	} else {
		messageID = msgID[0]
	}

	_, err := n.js.Publish(subject, message, nats.MsgId(messageID)) // Use message ID for deduplication
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	return nil
}

// Subscribe subscribes to a NATS JetStream subject with a queue group and manual acknowledgment
func (n *NATSBroker) Subscribe(subject, group string, handler func([]byte) ([]byte, error)) error {
	_, err := n.js.QueueSubscribe(subject, group, func(msg *nats.Msg) {
		n.processMessage(msg, handler)
	}, nats.ManualAck()) // Enable manual acknowledgment
	return err
}

// processMessage processes the message and checks Redis for deduplication
func (n *NATSBroker) processMessage(msg *nats.Msg, handler func([]byte) ([]byte, error)) {
	// Get the message ID from the message headers
	msgID := msg.Header.Get("Nats-Msg-Id")
	if msgID == "" {
		// If no message ID, reject the message (this should never happen)
		msg.Respond([]byte("No Message ID found"))
		msg.Ack()
		return
	}

	// Check Redis to see if this message ID has already been processed
	exists, err := n.redis.Get(n.ctx, msgID).Result()
	if err == redis.Nil {
		// Message ID not found, process the message
		response, err := handler(msg.Data)
		if err != nil {
			// Handle error and respond with failure message
			msg.Respond([]byte("Error processing request"))
		} else {
			// Acknowledge the message
			msg.Ack()

			// Store the message ID in Redis with a TTL after it is acknowledged
			ttl := 10 * time.Minute // Set the TTL for processed messages
			n.redis.Set(n.ctx, msgID, "processed", ttl)

			// Respond with success
			msg.Respond(response)
		}
	} else if exists == "processed" {
		// Message ID has already been processed, acknowledge and ignore
		msg.Ack()
	} else if err != nil {
		// Handle Redis error
		msg.Respond([]byte("Error accessing Redis"))
		msg.Ack()
	}
}
