package workflows

import (
	"time"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/stt/activities"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

type SendFinishedEvent struct {
	cfg         *config.Config
	db          models.DB
	sstActivity *activities.SendFinishedEvent
}

func NewSendFinishedEvent(cfg *config.Config, db models.DB, ssActivity *activities.SendFinishedEvent) *SendFinishedEvent {
	return &SendFinishedEvent{
		cfg:         cfg,
		db:          db,
		sstActivity: ssActivity,
	}
}

func (w *SendFinishedEvent) SendFinishedEventWorkflow(ctx workflow.Context, input activities.SpeechToTextInput) error {
	ao := workflow.ActivityOptions{
		StartToCloseTimeout: time.Minute * 10,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}
	ctx = workflow.WithActivityOptions(ctx, ao)

	err := workflow.ExecuteActivity(ctx, w.sstActivity.SendFinishedEvent, input).Get(ctx, nil)
	if err != nil {
		return err
	}

	return nil
}
