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

type UploadFile struct {
	cfg      *config.Config
	db       models.DB
	activity *activities.UploadFile
}

func NewUploadFile(cfg *config.Config, db models.DB, ssActivity *activities.UploadFile) *UploadFile {
	return &UploadFile{
		cfg:      cfg,
		db:       db,
		activity: ssActivity,
	}
}

func (s *UploadFile) UploadFileWorkflow(ctx workflow.Context, input activities.SpeechToTextInput) error {
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
	err := workflow.ExecuteActivity(ctx, s.activity.UploadFile, input).Get(ctx, &input)
	if err != nil {
		return err
	}

	if err := events.Next(types.WorkflowProcessFileTopic, input); err != nil {
		// c.JSON(http.StatusInternalServerError, fmt.Errorf("error sending the event: %v", err))
		return fmt.Errorf("error sending the %s event: %v", types.WorkflowProcessFileTopic, err)
	}

	return nil
}
