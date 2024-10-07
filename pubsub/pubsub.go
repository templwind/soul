package pubsub

type MessageBroker interface {
	Publish(subject string, message []byte) error
	Subscribe(subject string, handler func([]byte) ([]byte, error)) error
}
