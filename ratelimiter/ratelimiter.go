package ratelimiter

import (
	"log"
	"sync"
	"time"

	"github.com/templwind/soul/k8sutil"
	"golang.org/x/sync/semaphore"
	"golang.org/x/time/rate"
)

// RateLimiterConfig holds configuration for rate limiting
type RateLimiterConfig struct {
	TotalRPM       int // Total Requests Per Minute allowed by OpenAI
	MaxConcurrency int // Maximum concurrent requests allowed
	InstanceCount  int // Number of instances running
}

// RateLimiter holds the rate limiter and semaphore
type RateLimiter struct {
	Limiter   *rate.Limiter
	Semaphore *semaphore.Weighted
	mu        sync.Mutex
}

func (rl *RateLimiter) UpdateLimits(cfg *RateLimiterConfig, instanceCount int) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	perInstanceRPM := cfg.TotalRPM / instanceCount
	perInstanceRPS := float64(perInstanceRPM) / 60.0
	perInstanceConcurrency := cfg.MaxConcurrency / instanceCount

	// Update the rate limiter's limit and burst
	rl.Limiter.SetLimit(rate.Limit(perInstanceRPS))
	rl.Limiter.SetBurst(int(perInstanceRPS) * 2) // Adjust burst as needed

	// Update the semaphore for concurrency control
	rl.Semaphore = semaphore.NewWeighted(int64(perInstanceConcurrency))
}

// StartInstanceCountUpdater starts a goroutine to update the rate limiter's limits based on the instance count
func (rl *RateLimiter) StartInstanceCountUpdater(appLabel string, ticker *time.Ticker, cfg *RateLimiterConfig) {
	go func() {
		defer ticker.Stop()
		for {
			<-ticker.C
			instanceCount, err := k8sutil.GetInstanceCount(appLabel)
			if err != nil || instanceCount == 0 {
				log.Printf("Failed to get instance count, defaulting to 1")
				instanceCount = 1
			}
			rl.UpdateLimits(cfg, instanceCount)
		}
	}()
}

// NewRateLimiter creates a new RateLimiter based on the config
func NewRateLimiter(config RateLimiterConfig) *RateLimiter {
	perInstanceRPM := config.TotalRPM / config.InstanceCount
	perInstanceRPS := perInstanceRPM / 60 // Convert RPM to RPS
	perInstanceConcurrency := config.MaxConcurrency / config.InstanceCount

	rateLimit := rate.Limit(perInstanceRPS)
	burstLimit := int(perInstanceRPS) * 2
	limiter := rate.NewLimiter(rateLimit, burstLimit)

	semaphore := semaphore.NewWeighted(int64(perInstanceConcurrency))

	return &RateLimiter{
		Limiter:   limiter,
		Semaphore: semaphore,
	}
}
