package service

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"{{.serviceName}}/internal/config"
	"{{.serviceName}}/internal/events"
	"{{.serviceName}}/internal/models"
	"{{.serviceName}}/internal/types"
	"{{.serviceName}}/internal/workflow/activities"
	"{{.serviceName}}/internal/workflow/workflows"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/worker"
)

const Queue = "BILLING_QUEUE"

type BillingService struct {
	shutdownSignal                   chan struct{}
	client                           client.Client
	cfg                              *config.Config
	db                               models.DB
	chargeCardWorkflow               *workflows.ChargeCard
	chargeCardActivity               *activities.ChargeCard
	verifyTransactionWorkflow        *workflows.VerifyTransaction
	verifyTransactionActivity        *activities.VerifyTransaction
	handleTransactionOutcomeWorkflow *workflows.HandleTransactionOutcome
	handleTransactionOutcomeActivity *activities.HandleTransactionOutcome
}

func NewBillingService(cfg *config.Config, db models.DB) *BillingService {
	temporalClient, err := client.Dial(client.Options{
		HostPort: "temporal:7233",
	})
	if err != nil {
		log.Fatalln("Unable to create Temporal client:", err)
	}

	return &BillingService{
		shutdownSignal: make(chan struct{}),
		client:         temporalClient,
		cfg:            cfg,
		db:             db,
	}
}

func (s *BillingService) StartSubscribers() *BillingService {
	go func() {
		var wg sync.WaitGroup

		subscribe := func(topic string, handler func(context.Context, any) error) {
			wg.Add(1)
			go func() {
				defer wg.Done()
				sub := events.Subscribe(topic, handler)
				defer func() {
					events.Unsubscribe(sub)
					log.Printf("Unsubscribed from %s", topic)
				}()

				select {
				case <-s.shutdownSignal: // Assume you have a shutdown signal mechanism
					return
				}
			}()
		}

		subscribe(types.WorkflowChargeCardTopic, func(ctx context.Context, workflowInput any) error {
			if input, ok := workflowInput.(activities.BillingInput); ok {
				workflowRun, err := s.startChargeCardWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the ChargeCard workflow: %v", err)
				}
				log.Printf("Started ChargeCard workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		subscribe(types.WorkflowVerifyTransactionTopic, func(ctx context.Context, workflowInput any) error {
			if input, ok := workflowInput.(activities.BillingInput); ok {
				workflowRun, err := s.startVerifyTransactionWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the VerifyTransaction workflow: %v", err)
				}
				log.Printf("Started VerifyTransaction workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		subscribe(types.WorkflowHandleTransactionOutcomeTopic, func(ctx context.Context, workflowInput any) error {
			if input, ok := workflowInput.(activities.BillingInput); ok {
				workflowRun, err := s.startHandleTransactionOutcomeWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the HandleTransactionOutcome workflow: %v", err)
				}
				log.Printf("Started HandleTransactionOutcome workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		// Block here until the application is shutting down
		wg.Wait()
	}()
	return s
}

func (s *BillingService) StartWorkers(numWorkers int) *BillingService {
	s.chargeCardActivity = activities.NewChargeCard(s.cfg, s.db)
	s.verifyTransactionActivity = activities.NewVerifyTransaction(s.cfg, s.db)
	s.handleTransactionOutcomeActivity = activities.NewHandleTransactionOutcome(s.cfg, s.db)
	s.chargeCardWorkflow = workflows.NewChargeCard(s.cfg, s.db, s.chargeCardActivity)
	s.verifyTransactionWorkflow = workflows.NewVerifyTransaction(s.cfg, s.db, s.verifyTransactionActivity)
	s.handleTransactionOutcomeWorkflow = workflows.NewHandleTransactionOutcome(s.cfg, s.db, s.handleTransactionOutcomeActivity)

	for i := 0; i < numWorkers; i++ {
		go s.startWorker()
	}

	return s
}

func (s *BillingService) startWorker() {
	w := worker.New(s.client, Queue, worker.Options{})

	// Register Workflow functions.
	w.RegisterWorkflow(s.chargeCardWorkflow.ChargeCardWorkflow)
	w.RegisterWorkflow(s.verifyTransactionWorkflow.VerifyTransactionWorkflow)
	w.RegisterWorkflow(s.handleTransactionOutcomeWorkflow.HandleTransactionOutcomeWorkflow)

	// Register Activity functions.
	w.RegisterActivity(s.chargeCardActivity.ChargeCard)
	w.RegisterActivity(s.verifyTransactionActivity.VerifyTransaction)
	w.RegisterActivity(s.handleTransactionOutcomeActivity.HandleTransactionOutcome)

	// Start listening to the Task Queue.
	err := w.Run(worker.InterruptCh())
	if err != nil {
		log.Fatalln("Unable to start Worker", err)
	}
}

func (s *BillingService) startChargeCardWorkflow(workflowInput activities.BillingInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		ID:        "charge_card_workflow_" + workflowInput.TransactionID,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.chargeCardWorkflow.ChargeCardWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start ChargeCard workflow:", err)
		return nil, err
	}

	log.Printf("Started ChargeCard workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *BillingService) startVerifyTransactionWorkflow(workflowInput activities.BillingInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		ID:        "verify_transaction_workflow_" + workflowInput.TransactionID,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.verifyTransactionWorkflow.VerifyTransactionWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start VerifyTransaction workflow:", err)
		return nil, err
	}

	log.Printf("Started VerifyTransaction workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *BillingService) startHandleTransactionOutcomeWorkflow(workflowInput activities.BillingInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		ID:        "handle_transaction_outcome_workflow_" + workflowInput.TransactionID,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.handleTransactionOutcomeWorkflow.HandleTransactionOutcomeWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start HandleTransactionOutcome workflow:", err)
		return nil, err
	}

	log.Printf("Started HandleTransactionOutcome workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *BillingService) Client() client.Client {
	return s.client
}

func (s *BillingService) Close() {
	close(s.shutdownSignal)
	s.client.Close()
}
