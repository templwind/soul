package pubsub

import (
	"github.com/nats-io/nats.go"
)

type NATSBroker struct {
	conn *nats.Conn
}

func NewNATSBroker(url string) (*NATSBroker, error) {
	nc, err := nats.Connect(url)
	if err != nil {
		return nil, err
	}
	return &NATSBroker{conn: nc}, nil
}

// Publish a message to a NATS subject
func (n *NATSBroker) Publish(subject string, message []byte) error {
	return n.conn.Publish(subject, message)
}

// Subscribe to a NATS subject
func (n *NATSBroker) Subscribe(subject string, handler func([]byte) ([]byte, error)) error {
	_, err := n.conn.Subscribe(subject, func(msg *nats.Msg) {
		response, err := handler(msg.Data)
		if err != nil {
			// Handle error
			msg.Respond([]byte("Error processing request"))
		} else {
			msg.Respond(response) // Send response back as acknowledgment
		}
	})
	return err
}
