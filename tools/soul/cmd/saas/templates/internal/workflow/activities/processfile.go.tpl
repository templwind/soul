package activities

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"{{ .serviceName }}/internal/chatgpt"
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/types"
)

type ProcessFile struct {
	cfg            *config.Config
	db             models.DB
	chatGPTService *chatgpt.ChatGPTService
	basePrompt     string
}

func NewProcessFile(cfg *config.Config, db models.DB, chatGPTService *chatgpt.ChatGPTService) *ProcessFile {
	// Load the prompt from the prompt.txt
	promptPath := filepath.Join(cfg.PromptsPath, "prompt.txt")
	promptB, err := os.ReadFile(promptPath)
	if err != nil {
		log.Printf("failed to read prompt.txt: %w", err)
		os.Exit(0)
	}

	return &ProcessFile{
		cfg:            cfg,
		db:             db,
		chatGPTService: chatGPTService,
		basePrompt:     string(promptB),
	}
}

// //////////////////////////////////////////////////////
//
// # ProcessFile processes the recording transcription with GPT
//
// //////////////////////////////////////////////////////
func (p *ProcessFile) ProcessFile(input *SpeechToTextInput) (*SpeechToTextInput, error) {
	// fmt.Printf("Sending prompt to %s...\n", p.cfg.GPT.Model)

	recordingModel, _ := models.RecordingByID(context.Background(), p.db, input.Recording.ID)
	// recordingModel.Transcription.

	transcription := types.Transcription{}
	if recordingModel.Transcription.Valid {
		transcription = recordingModel.Transcription.Transcription
	}

	// if err := json.Unmarshal(recordingModel.Transcription), &transcription); err != nil {
	// 	return input, fmt.Errorf("failed to unmarshal transcription: %w", err)
	// }

	// Convert the prompt from []byte to string
	prompt := fmt.Sprintf("%s\n\n%s\n\n%s: %s %s\n\nPatient Name: %s\nPatient Gender: %s", p.basePrompt, transcription.Text, input.User.Title, input.User.FirstName, input.User.LastName, strings.Split(recordingModel.Name, "_")[0], recordingModel.Gender)

	// fmt.Println("Prompt:", prompt)

	bp, err := p.chatGPTService.ProcessPrompt(recordingModel.PublicID.String(), prompt)
	if err != nil {
		return input, fmt.Errorf("failed to process prompt: %w", err)
	}

	// fmt.Println("Received response from GPT-4...", bp)
	// fmt.Printf("Received response from %s...\n\n%s", p.cfg.GPT.Model, bp)

	// parse the soap note
	soapNote := p.parseSOAPNote(bp)

	// set the soap note
	transcription.SOAPNote = soapNote

	// convert the whole to json
	transcriptionB, err := json.Marshal(transcription)
	if err != nil {
		return input, fmt.Errorf("failed to marshal transcription: %w", err)
	}

	// set the recording transcription
	recordingModel.Transcription, _ = models.NewNullTranscription(transcriptionB)

	// set the recording complaint
	recordingModel.Complaint = types.NewNullString(soapNote.ChiefComplaint)

	// fmt.Println("Saving recording...")

	// save the recording
	return input, recordingModel.Update(context.Background(), p.db)
}

// ParseSOAPNote parses the given text into a SOAPNote struct
func (p *ProcessFile) parseSOAPNote(text string) types.SOAPNote {
	sections := strings.Split(text, "---")
	var note types.SOAPNote

	for _, section := range sections {
		section = strings.TrimSpace(section)
		if strings.HasPrefix(section, "Subjective:") {
			note.Subjective = strings.TrimSpace(strings.TrimPrefix(section, "Subjective:"))
		} else if strings.HasPrefix(section, "Objective:") {
			note.Objective = strings.TrimSpace(strings.TrimPrefix(section, "Objective:"))
		} else if strings.HasPrefix(section, "Assessment:") {
			note.Assessment = strings.TrimSpace(strings.TrimPrefix(section, "Assessment:"))
		} else if strings.HasPrefix(section, "Plan:") {
			note.Plan = strings.TrimSpace(strings.TrimPrefix(section, "Plan:"))
		} else if strings.HasPrefix(section, "Patient Instructions:") {
			note.PatientInstructions = strings.TrimSpace(strings.TrimPrefix(section, "Patient Instructions:"))
		} else if strings.HasPrefix(section, "Chief Complaint:") {
			note.ChiefComplaint = strings.TrimSpace(strings.TrimPrefix(section, "Chief Complaint:"))
		}
	}

	return note
}
