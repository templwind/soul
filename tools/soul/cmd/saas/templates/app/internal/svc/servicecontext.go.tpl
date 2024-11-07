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
	AWSSession         *session.Session
	DWSession          *session.Session
	ChatGPTService     *chatgpt.ChatGPTService
	RateLimiter        *ratelimiter.RateLimiter
	{{if not .isService}}
	StorageManager     *storagemanager.StorageManager
	SystemEmailClient  emailTypes.EmailClient
	{{end -}}
	JobManager         *jobs.JobManager
	PubSubBroker       pubsub.Broker
}

func NewServiceContext(c *{{.config}}) *ServiceContext {
	sqlxDB := db.MustConnect(
		db.WithDSN(c.DSN),
	).GetDB()
	sqlxDB.SetMaxOpenConns(5)
	sqlxDB.SetMaxIdleConns(5)

	// Create an AWS session
	awsSession := awssession.MustNewSession(awssession.Config{
		AWS:           c.AWS,
		MaxRetries:    3,
		RetryInterval: 2 * time.Second,
	})

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

	return &ServiceContext{
		Config: c,
		DB:  sqlxDB,
		{{.middlewareAssignment -}}
		{{if not .isService}}
		Menus:              c.InitMenus(),
		Session:            systemSession.NewSession(c),
		AWSSession:         awsSession,
		SystemEmailClient: client.MustNewClient(emailTypes.SESClient, &emailTypes.EmailAuth{
			AWSSession: awsSession,
		}),
		{{end -}}
		ChatGPTService: chatGPTService,
		RateLimiter:    rateLimiter,
		{{if not .isService}}
		StorageManager: storagemanager.MustNewStorageManager(context.TODO(), c, sqlxDB, 85.0),
		{{end -}}
		JobManager:     jobManager,
		PubSubBroker:   pubsub.MustNewNATSBroker(c.Nats.URL, c.Redis.URL),
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