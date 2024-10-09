package jobs

import (
	"log"

	"github.com/robfig/cron/v3"
)

type JobManager struct {
	cron *cron.Cron
}

// NewJobManager creates a new JobManager
func NewJobManager() *JobManager {
	return &JobManager{
		cron: cron.New(cron.WithSeconds()), // WithSeconds allows cron expressions with seconds precision
	}
}

// Start starts the job manager, running all registered jobs
func (jm *JobManager) Start() {
	go jm.cron.Start() // Ensure Start is running in a goroutine
	log.Println("Job Manager started")
}

// Stop stops the job manager and all running jobs
func (jm *JobManager) Stop() {
	jm.cron.Stop()
	log.Println("Job Manager stopped")
}

// AddJob registers a new cron job with the given schedule and function asynchronously
func (jm *JobManager) AddJob(schedule string, jobFunc func()) error {
	// Wrap job registration in a goroutine
	go func() {
		_, err := jm.cron.AddFunc(schedule, func() {
			go jobFunc() // Make sure the job itself is async
		})
		if err != nil {
			log.Printf("Error adding job: %v", err)
		} else {
			log.Printf("Job registered with schedule: %s\n", schedule)
		}
	}()
	return nil
}
