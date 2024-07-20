package activities

import (
	"log"
	"os"
	"path/filepath"

	"{{ .serviceName }}/internal/chatgpt"
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/events"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/types"
	"{{ .serviceName }}/internal/ui/components/toast"

	"github.com/templwind/soul"
)

type SendFinishedEvent struct {
	cfg            *config.Config
	db             models.DB
	chatGPTService *chatgpt.ChatGPTService
	basePrompt     string
}

func NewSendFinishedEvent(cfg *config.Config, db models.DB, chatGPTService *chatgpt.ChatGPTService) *SendFinishedEvent {
	// Load the prompt from the prompt.txt
	promptPath := filepath.Join(cfg.PromptsPath, "prompt.txt")
	promptB, err := os.ReadFile(promptPath)
	if err != nil {
		log.Printf("failed to read prompt.txt: %w", err)
		os.Exit(0)
	}

	return &SendFinishedEvent{
		cfg:            cfg,
		db:             db,
		chatGPTService: chatGPTService,
		basePrompt:     string(promptB),
	}
}

func (s *SendFinishedEvent) SendFinishedEvent(input *SpeechToTextInput) (*SpeechToTextInput, error) {

	template, _ := templwind.ComponentToString(toast.New(
		toast.WithMessage("Recording Processing Complete"),
	))
	// todo: add your logic here and delete this line
	resp := &types.FinishedProcessingEvent{
		EncounterID: input.Recording.PublicID.String(),
		Template:    template,
	}

	// send the response to the client via the events engine
	return nil, events.Next(types.TopicServerFinishedProcessing, resp)
}
