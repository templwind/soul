package main

import (
	"context"
	"embed"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/modules"

	_ "github.com/a-h/templ"
	"github.com/joho/godotenv"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

//go:embed etc/config.yaml
var configFile embed.FS

// go:embed all:assets/*
// var assetsPath embed.FS

//go:embed db/migrations/*.sql
var embededMigrations embed.FS

func main() {
	err := godotenv.Load(".env", ".envrc")
	if err != nil {
		log.Println("Error loading .env file")
	}

	configBytes, err := configFile.ReadFile("etc/config.yaml")
	if err != nil {
		log.Fatalf("Failed to read config file: %v", err)
	}

	// Expand environment variables
	configBytes = []byte(os.ExpandEnv(string(configBytes)))

	var c config.Config
	err = config.LoadConfigFromYamlBytes(configBytes, &c)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Set the embedded migrations
	c.EmbededMigrations = embededMigrations

	// Create a context that listens for the interrupt signal from the OS.
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	// Create the service context instance
	svcCtx := svc.NewServiceContext(ctx, &c)

	// Start the web server
	e := echo.New()
	// e.Use(middleware.HTTPSRedirect())
	e.Use(middleware.RemoveTrailingSlashWithConfig(middleware.TrailingSlashConfig{
		RedirectCode: http.StatusMovedPermanently,
	}))

	e.Static("/static", "assets")

	// register modules
	modules.RegisterAll(svcCtx, e)

	// Start the server
	go func() {
		if err := e.Start(":8888"); err != nil && err != http.ErrServerClosed {
			e.Logger.Fatal("shutting down the server")
		}
	}()

	// Wait for the context to be cancelled (which happens when we receive an interrupt signal)
	{{ "<-ctx.Done()" | safeHTML }}
	log.Println("Shutting down gracefully, press Ctrl+C again to force")

	// Create a new context for the shutdown process
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Attempt to gracefully shutdown the server
	if err := e.Shutdown(shutdownCtx); err != nil {
		e.Logger.Fatal(err)
	}
}
