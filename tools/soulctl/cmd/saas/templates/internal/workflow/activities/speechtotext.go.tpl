package activities

import (
	"{{ .serviceName }}/internal/models"
)

type SpeechToTextInput struct {
	FilePath  string
	User      *models.User
	Recording *models.Recording
}
