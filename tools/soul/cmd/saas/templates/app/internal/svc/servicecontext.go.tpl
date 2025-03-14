package svc

import (
	{{.imports}}
)

type ServiceContext struct {
	Config           *{{.config}}
	DB               *sqlx.DB
	{{.middleware -}}
	{{if not .isService}}
	Session            *systemSession.Session
	Menus              map[string][]config.MenuEntry
	{{end -}}
	ChatGPTService     *chatgpt.ChatGPTService
	RateLimiter        *ratelimiter.RateLimiter
	JobManager         *jobs.JobManager
	PubSubBroker       pubsub.Broker
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
	rateLimiter := ratelimiter.NewRateLimiter(rateLimiterConfig)

	// Initialize the ChatGPTService with the RateLimiter
	chatGPTService := chatgpt.MustNewChatGPTService(&c.GPT, rateLimiter)

	// Initialize the job manager
	jobManager := jobs.NewJobManager()

	// customStatic := middleware.CustomStaticMiddleware("build", c.EmbeddedFS["build"], c.Environment == "production")

	// Create a PubSub broker (use NoOpBroker if NATS is not available)
	var pubSubBroker pubsub.Broker
	if c.Nats.URL == "" || c.Nats.URL == "nats://nats:4222" {
		log.Println("NATS URL not provided or using default. Using no-op broker instead.")
		pubSubBroker = &NoOpBroker{}
	} else {
		// Try to create a real NATS broker
		broker, err := pubsub.NewNATSBroker(c.Nats.URL, c.Redis.URL)
		if err != nil {
			log.Printf("Failed to create NATS broker: %v. Using no-op broker instead.", err)
			pubSubBroker = &NoOpBroker{}
		} else {
			pubSubBroker = broker
		}
	}

	return &ServiceContext{
		Config: c,
		DB:  sqlxDB,
		{{.middlewareAssignment -}}
		{{if not .isService}}
		Menus:              c.InitMenus(),
		Session:            systemSession.NewSession(c),
		{{end -}}
		ChatGPTService: chatGPTService,
		RateLimiter:    rateLimiter,
		JobManager:     jobManager,
		PubSubBroker:   pubSubBroker,
		EventHub:       sse.NewEventHub(),
	}
}

func (c *ServiceContext) StartInstanceCountUpdater(appLabel string, cfg *config.GPT) {
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			<-ticker.C
			instanceCount, err := k8sutil.GetInstanceCount(appLabel)
			if err != nil || instanceCount == 0 {
				log.Printf("Failed to get instance count, defaulting to 1")
				instanceCount = 1
			}
			c.RateLimiter.UpdateLimits(cfg, instanceCount)
		}
	}()
}

// NoOpBroker is a no-op implementation of the pubsub.Broker interface for when NATS is not available
type NoOpBroker struct{}

func (b *NoOpBroker) Publish(subject string, message []byte, msgID ...string) error {
	log.Printf("NoOpBroker: Would publish to subject %s", subject)
	return nil
}

func (b *NoOpBroker) Subscribe(subject string, group string, handler func([]byte) ([]byte, error)) error {
	log.Printf("NoOpBroker: Would subscribe to subject %s with group %s", subject, group)
	return nil
}

func (b *NoOpBroker) CreateStream(streamName, subject string, dedupWindow time.Duration) error {
	log.Printf("NoOpBroker: Would create stream %s for subject %s with dedup window %v", streamName, subject, dedupWindow)
	return nil
}