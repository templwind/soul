package svc

import (
	"log"
	"time"

	"backend/internal/config"
	"backend/internal/jobs"
	"backend/internal/middleware"
	systemSession "backend/internal/session"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo/v4"
	_ "github.com/lib/pq"
	"github.com/templwind/soul/db"
	"github.com/templwind/soul/events"
	"github.com/templwind/soul/k8sutil"
	"github.com/templwind/soul/pubsub"
	"github.com/templwind/soul/ratelimiter"
	//  "github.com/templwind/soul/webserver/sse"
)

type ServiceContext struct {
	Config       *config.Config
	DB           *sqlx.DB
	NoCache      echo.MiddlewareFunc
	Session      *systemSession.Session
	RateLimiter  *ratelimiter.RateLimiter
	JobManager   *jobs.JobManager
	PubSubBroker pubsub.Broker
	EventHub     *sse.EventHub
}

func NewServiceContext(c *config.Config) *ServiceContext {
	sqlxDB := db.MustConnect(
		db.WithDSN(c.DSN),
	).GetDB()
	sqlxDB.SetMaxOpenConns(5)
	sqlxDB.SetMaxIdleConns(5)

	// Get the instance count from Kubernetes
	instanceCount, err := k8sutil.GetInstanceCount("backend") // Replace with your actual app label
	if err != nil || instanceCount == 0 {
		log.Printf("Failed to get instance count, defaulting to 1")
		instanceCount = 1
	}

	// Initialize the RateLimiter
	rateLimiterConfig := ratelimiter.RateLimiterConfig{
		TotalRPM:       c.GPT.TotalRPM,       // Total RPM from configuration
		MaxConcurrency: c.GPT.MaxConcurrency, // Max concurrency from configuration
		InstanceCount:  instanceCount,
	}

	// Initialize the rate limiter
	rateLimiter := ratelimiter.NewRateLimiter(rateLimiterConfig)
	if c.RateLimiter.TotalRPM != 0 {
		rateLimiter.UpdateLimits(&c.RateLimiter, instanceCount)
	}

	// Start the instance count updater
	rateLimiter.StartInstanceCountUpdater("backend", time.NewTicker(30*time.Second), &rateLimiterConfig)

	// Initialize the job manager
	jobManager := jobs.NewJobManager()

	// customStatic := middleware.CustomStaticMiddleware("build", c.EmbeddedFS["build"], c.Environment == "production")

	// Create a PubSub broker (use events.NoOpBroker if NATS is not available)
	var pubSubBroker pubsub.Broker
	if c.Nats.URL == "" || c.Nats.URL == "nats://nats:4222" {
		log.Println("NATS URL not provided or using default. Using no-op broker instead.")
		pubSubBroker = &events.NoOpBroker{}
	} else {
		// Try to create a real NATS broker
		broker, err := pubsub.NewNATSBroker(c.Nats.URL, c.Redis.URL)
		if err != nil {
			log.Printf("Failed to create NATS broker: %v. Using no-op broker instead.", err)
			pubSubBroker = &events.NoOpBroker{}
		} else {
			pubSubBroker = broker
		}
	}

	return &ServiceContext{
		Config:       c,
		DB:           sqlxDB,
		NoCache:      middleware.NewNoCacheMiddleware().Handle,
		Session:      systemSession.NewSession(c),
		RateLimiter:  rateLimiter,
		JobManager:   jobManager,
		PubSubBroker: pubSubBroker,
		EventHub:     sse.NewEventHub(),
	}
}
