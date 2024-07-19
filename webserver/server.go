package webserver

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/labstack/echo/v4"
)

type ServerOpt func(*Server)

type Server struct {
	// Echo instance
	Echo *echo.Echo

	// WebServerConf
	conf WebServerConf

	// Middleware
	middleware []echo.MiddlewareFunc
}

func WithMiddleware(middleware ...echo.MiddlewareFunc) ServerOpt {
	return func(s *Server) {
		s.middleware = middleware
	}
}

func MustNewServer(c WebServerConf, opts ...ServerOpt) *Server {
	// Create a new Echo instance
	e := echo.New()

	// Create a new server
	server := &Server{
		Echo: e,
		conf: c,
	}

	// Apply options
	for _, opt := range opts {
		opt(server)
	}

	return server
}

func (s *Server) Start() {
	if err := s.Echo.Start(fmt.Sprintf("%s:%d", s.conf.Host, s.conf.Port)); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Shutting down the server: %v", err)
	}
}

func (s *Server) Stop() {
	// Create a context that listens for the interrupt signal from the OS.
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Wait for interrupt signal to gracefully shutdown the server with a timeout of 10 seconds.
	<-ctx.Done()
	log.Println("Received shutdown signal, shutting down gracefully...")

	// Create a context with a timeout of 1 second.
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()
	if err := s.Echo.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server shutdown failed: %v", err)
	}

	log.Println("Server shutdown complete")
}
