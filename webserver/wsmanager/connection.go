package wsmanager

import (
	"net"
	"sync"
)

type Connection struct {
	Conn net.Conn
	mu   sync.Mutex
}

func NewConnection(conn net.Conn) *Connection {
	return &Connection{
		Conn: conn,
	}
}
