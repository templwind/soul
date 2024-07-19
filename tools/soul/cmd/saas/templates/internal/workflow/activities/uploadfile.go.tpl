package activities

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"{{ .serviceName }}/internal/chatgpt"
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
)

type UploadFile struct {
	cfg            *config.Config
	db             models.DB
	chatGPTService *chatgpt.ChatGPTService
	basePrompt     string
}

func NewUploadFile(cfg *config.Config, db models.DB, chatGPTService *chatgpt.ChatGPTService) *UploadFile {
	// Load the prompt from the prompt.txt
	promptPath := filepath.Join(cfg.PromptsPath, "prompt.txt")
	promptB, err := os.ReadFile(promptPath)
	if err != nil {
		log.Printf("failed to read prompt.txt: %w", err)
		os.Exit(0)
	}

	return &UploadFile{
		cfg:            cfg,
		db:             db,
		chatGPTService: chatGPTService,
		basePrompt:     string(promptB),
	}
}

// //////////////////////////////////////////////////////
//
// # UploadFile uploads the given file to the ASR service
//
// //////////////////////////////////////////////////////
func (u *UploadFile) UploadFile(input *SpeechToTextInput) (*SpeechToTextInput, error) {
	if u.cfg == nil {
		return input, fmt.Errorf("config is nil")
	}
	if u.db == nil {
		return input, fmt.Errorf("DB is nil")
	}

	ctx := context.Background()

	// Parse the file path to get the recording ID
	recordingID := strings.Split(filepath.Base(input.FilePath), "-")[0]

	// Get the recording record from the database
	recordingPublicID := models.PublicID(recordingID)
	recordingModel, err := models.RecordingByPublicID(ctx, u.db, models.ToNullPublicID(recordingPublicID))
	if err != nil {
		return input, fmt.Errorf("failed to get recording record: %v", err)
	}

	file, err := os.Open(input.FilePath)
	if err != nil {
		return input, fmt.Errorf("failed to open file: %v", err)
	}
	defer file.Close()

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("audio_file", filepath.Base(input.FilePath))
	if err != nil {
		return input, fmt.Errorf("failed to create form file: %v", err)
	}

	if _, err = io.Copy(part, file); err != nil {
		return input, fmt.Errorf("failed to copy file data: %v", err)
	}
	if err = writer.Close(); err != nil {
		return input, fmt.Errorf("failed to close writer: %v", err)
	}

	// Construct the request URL with minimal query parameters
	reqURL := fmt.Sprintf("%s?output=json", u.cfg.WhisperAPI)
	request, err := http.NewRequest("POST", reqURL, body)
	if err != nil {
		return input, fmt.Errorf("failed to create request: %v", err)
	}
	request.Header.Set("Content-Type", writer.FormDataContentType())

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return input, fmt.Errorf("failed to send request: %v", err)
	}
	defer response.Body.Close()

	// Read and handle the response
	respBody, _ := io.ReadAll(response.Body)
	if response.StatusCode != http.StatusOK {
		return input, fmt.Errorf("bad status from ASR service: %s. Response: %s", response.Status, respBody)
	}

	recordingModel.Transcription, _ = models.NewNullTranscription(respBody)
	if err := recordingModel.Save(ctx, u.db); err != nil {
		return input, fmt.Errorf("failed to save response transcription to database: %v", err)
	}

	input.Recording = recordingModel

	return input, nil
}
