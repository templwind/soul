package svc

import (
	{{.imports}}
)

type ServiceContext struct {
	Config           *{{.config}}
	DB               *sqlx.DB
	{{.middleware -}}
	Session           *systemSession.Session
	RateLimiter       *ratelimiter.RateLimiter
	JobManager        *jobs.JobManager
	PubSubBroker      pubsub.Broker
	EventHub          *sse.EventHub
}

func NewServiceContext(c *{{.config}}) *ServiceContext {
	sqlxDB := db.MustConnect(
		db.WithDSN(c.DSN),
	).GetDB()
	sqlxDB.SetMaxOpenConns(5)
	sqlxDB.SetMaxIdleConns(5)

	// Get the instance count from Kubernetes
	instanceCount, err := k8sutil.GetInstanceCount("{{.serviceName}}") // Replace with your actual app label
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
	for _, limitCfg := range c.RateLimiters {
		if limitCfg.TotalRPM != 0 {
			rateLimiter.UpdateLimits(&limitCfg, instanceCount)
		}
	}

	// Start the instance count updater
	rateLimiter.StartInstanceCountUpdater("{{.serviceName}}", time.NewTicker(30 * time.Second), &rateLimiterConfig)

	// Initialize the job manager
	jobManager := jobs.NewJobManager()

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
		Config: c,
		DB:  sqlxDB,
		{{.middlewareAssignment -}}
		Session:        systemSession.NewSession(c),
		RateLimiter:    rateLimiter,
		JobManager:     jobManager,
		PubSubBroker:   pubSubBroker,
		EventHub:       sse.NewEventHub(),
	}
}
