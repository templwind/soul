package wsmanager

import (
	"net"
	"sync"
)

type Connection struct {
	conn net.Conn
	mu   sync.Mutex
}

func NewConnection(conn net.Conn) *Connection {
	return &Connection{
		conn: conn,
	}
}
