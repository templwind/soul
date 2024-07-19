package stt

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"{{ .serviceName }}/internal/chatgpt"
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/events"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/types"
	"{{ .serviceName }}/internal/workflow/activities"
	"{{ .serviceName }}/internal/workflow/workflows"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/worker"
)

const Queue = "_QUEUE"

type WorkflowService struct {
	shutdownSignal            chan struct{}
	client                    client.Client
	cfg                       *config.Config
	db                        models.DB
	chatGPTService            *chatgpt.ChatGPTService
	uploadFileWorkflow        *workflows.UploadFile
	uploadFileActivity        *activities.UploadFile
	processFileWorkflow       *workflows.ProcessFile
	processFileActivity       *activities.ProcessFile
	sendFinishedEventWorkflow *workflows.SendFinishedEvent
	sendFinishedEventActivity *activities.SendFinishedEvent
}

func NewWorkflowService(cfg *config.Config, db models.DB) *WorkflowService {
	temporalClient, err := client.Dial(client.Options{
		HostPort: "temporal:7233",
	})
	if err != nil {
		log.Fatalln("Unable to create Temporal client:", err)
	}

	return &WorkflowService{
		shutdownSignal: make(chan struct{}),
		client:         temporalClient,
		cfg:            cfg,
		db:             db,
		chatGPTService: chatgpt.MustNewChatGPTService(&cfg.GPT),
	}
}

func (s *WorkflowService) StartSubscribers() *WorkflowService {
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

		subscribe(types.WorkflowUploadFileTopic, func(ctx context.Context, workflowInput any) error {
			// fmt.Println("Received UploadFile event")
			if input, ok := workflowInput.(activities.SpeechToTextInput); ok {
				workflowRun, err := s.startUploadFileWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the UploadFile workflow: %v", err)
				}
				log.Printf("Started UploadFile workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		subscribe(types.WorkflowProcessFileTopic, func(ctx context.Context, workflowInput any) error {
			if input, ok := workflowInput.(activities.SpeechToTextInput); ok {
				workflowRun, err := s.startProcessFileWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the ProcessFile workflow: %v", err)
				}
				log.Printf("Started ProcessFile workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		subscribe(types.WorkflowSendFinishedEventTopic, func(ctx context.Context, workflowInput any) error {
			if input, ok := workflowInput.(activities.SpeechToTextInput); ok {
				workflowRun, err := s.startSendFinishedEventWorkflow(input)
				if err != nil {
					return fmt.Errorf("error starting the SendFinishedEvent workflow: %v", err)
				}
				log.Printf("Started SendFinishedEvent workflow with ID: %s", workflowRun.GetID())
				return nil
			}
			return fmt.Errorf("invalid input type")
		})

		// Block here until the application is shutting down
		wg.Wait()
	}()
	return s
}

func (s *WorkflowService) StartWorkers(numWorkers int) *WorkflowService {
	s.uploadFileActivity = activities.NewUploadFile(s.cfg, s.db, s.chatGPTService)
	s.processFileActivity = activities.NewProcessFile(s.cfg, s.db, s.chatGPTService)
	s.sendFinishedEventActivity = activities.NewSendFinishedEvent(s.cfg, s.db, s.chatGPTService)
	s.uploadFileWorkflow = workflows.NewUploadFile(s.cfg, s.db, s.UploadFileActivity)
	s.processFileWorkflow = workflows.NewProcessFile(s.cfg, s.db, s.ProcessFileActivity)
	s.sendFinishedEventWorkflow = workflows.NewSendFinishedEvent(s.cfg, s.db, s.SendFinishedEventActivity)

	for i := 0; i < numWorkers; i++ {
		go s.startWorker()
	}

	return s
}

func (s *WorkflowService) startWorker() {
	w := worker.New(s.client, Queue, worker.Options{})

	// Register Workflow functions.
	w.registerWorkflow(s.UploadFileWorkflow.UploadFileWorkflow)
	w.registerWorkflow(s.ProcessFileWorkflow.ProcessFileWorkflow)
	w.registerWorkflow(s.SendFinishedEventWorkflow.SendFinishedEventWorkflow)

	// Register Activity functions.
	w.registerActivity(s.UploadFileActivity.UploadFile)
	w.registerActivity(s.ProcessFileActivity.ProcessFile)
	w.registerActivity(s.SendFinishedEventActivity.SendFinishedEvent)

	// Start listening to the Task Queue.
	err := w.Run(worker.InterruptCh())
	if err != nil {
		log.Fatalln("Unable to start Worker", err)
	}
}

func (s *WorkflowService) startUploadFileWorkflow(workflowInput activities.SpeechToTextInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		id:        "_upload_file_workflow_" + workflowInput.FilePath,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.UploadFileWorkflow.UploadFileWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start UploadFile workflow:", err)
		return nil, err
	}

	log.Printf("Started UploadFile workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *WorkflowService) startProcessFileWorkflow(workflowInput activities.SpeechToTextInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		id:        "_process_file_workflow_" + workflowInput.FilePath,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.ProcessFileWorkflow.ProcessFileWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start ProcessFile workflow:", err)
		return nil, err
	}

	log.Printf("Started ProcessFile workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *WorkflowService) startSendFinishedEventWorkflow(workflowInput activities.SpeechToTextInput) (client.WorkflowRun, error) {
	options := client.StartWorkflowOptions{
		id:        "_send_finished_event_workflow_" + workflowInput.FilePath,
		TaskQueue: Queue,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second * 5,
			BackoffCoefficient: 2.0,
			MaximumInterval:    time.Minute * 5,
			MaximumAttempts:    3,
		},
	}

	workflowRun, err := s.client.ExecuteWorkflow(context.Background(), options, s.SendFinishedEventWorkflow.SendFinishedEventWorkflow, workflowInput)
	if err != nil {
		log.Fatalln("Unable to start SendFinishedEvent workflow:", err)
		return nil, err
	}

	log.Printf("Started SendFinishedEvent workflow with ID: %s", workflowRun.GetID())
	return workflowRun, nil
}

func (s *WorkflowService) Client() client.Client {
	return s.client
}

func (s *WorkflowService) Close() {
	close(s.shutdownSignal)
	s.client.Close()
}
