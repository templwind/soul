package workflows

import (
	"fmt"
	"time"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/events"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/stt/activities"
	"{{ .serviceName }}/internal/types"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

type ProcessFile struct {
	cfg         *config.Config
	db          models.DB
	sstActivity *activities.ProcessFile
}

func NewProcessFile(cfg *config.Config, db models.DB, ssActivity *activities.ProcessFile) *ProcessFile {
	return &ProcessFile{
		cfg:         cfg,
		db:          db,
		sstActivity: ssActivity,
	}
}

func (s *ProcessFile) ProcessFileWorkflow(ctx workflow.Context, input activities.SpeechToTextInput) error {
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

	// Upload the file
	err := workflow.ExecuteActivity(ctx, s.sstActivity.ProcessFile, input).Get(ctx, &input)
	if err != nil {
		return err
	}

	if err := events.Next(types.WorkflowSendFinishedEventTopic, input); err != nil {
		// c.JSON(http.StatusInternalServerError, fmt.Errorf("error sending the event: %v", err))
		return fmt.Errorf("error sending the %s event: %v", types.WorkflowSendFinishedEventTopic, err)
	}

	return nil
}
