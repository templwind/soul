package wsmanager

import "encoding/json"

type Message struct {
	ID      string          `json:"id"`
	Topic   string          `json:"topic"`
	Payload json.RawMessage `json:"payload"`
	Sender  *Connection     `json:"-"`
}
