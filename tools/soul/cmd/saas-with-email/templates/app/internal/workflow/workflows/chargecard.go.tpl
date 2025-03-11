package workflows

import (
	"time"

	"{{.serviceName}}/internal/config"
	"{{.serviceName}}/internal/models"
	"{{.serviceName}}/internal/workflow/activities"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

type ChargeCard struct {
	cfg          *config.Config
	db           models.DB
	cardActivity *activities.ChargeCard
}

func NewChargeCard(cfg *config.Config, db models.DB, cardActivity *activities.ChargeCard) *ChargeCard {
	return &ChargeCard{
		cfg:          cfg,
		db:           db,
		cardActivity: cardActivity,
	}
}

func (s *ChargeCard) ChargeCardWorkflow(ctx workflow.Context, input activities.BillingInput) error {
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

	err := workflow.ExecuteActivity(ctx, s.cardActivity.ChargeCard, input).Get(ctx, &input)
	if err != nil {
		return err
	}

	return nil
}

type VerifyTransaction struct {
	cfg                 *config.Config
	db                  models.DB
	transactionActivity *activities.VerifyTransaction
}

func NewVerifyTransaction(cfg *config.Config, db models.DB, transactionActivity *activities.VerifyTransaction) *VerifyTransaction {
	return &VerifyTransaction{
		cfg:                 cfg,
		db:                  db,
		transactionActivity: transactionActivity,
	}
}

func (s *VerifyTransaction) VerifyTransactionWorkflow(ctx workflow.Context, input activities.BillingInput) error {
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

	err := workflow.ExecuteActivity(ctx, s.transactionActivity.VerifyTransaction, input).Get(ctx, &input)
	if err != nil {
		return err
	}

	return nil
}

type HandleTransactionOutcome struct {
	cfg             *config.Config
	db              models.DB
	outcomeActivity *activities.HandleTransactionOutcome
}

func NewHandleTransactionOutcome(cfg *config.Config, db models.DB, outcomeActivity *activities.HandleTransactionOutcome) *HandleTransactionOutcome {
	return &HandleTransactionOutcome{
		cfg:             cfg,
		db:              db,
		outcomeActivity: outcomeActivity,
	}
}

func (s *HandleTransactionOutcome) HandleTransactionOutcomeWorkflow(ctx workflow.Context, input activities.BillingInput) error {
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

	err := workflow.ExecuteActivity(ctx, s.outcomeActivity.HandleTransactionOutcome, input).Get(ctx, &input)
	if err != nil {
		return err
	}

	return nil
}
