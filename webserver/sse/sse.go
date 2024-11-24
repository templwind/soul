package sse

import (
	"time"

	"github.com/google/uuid"
)

// Status constants for common event states
const (
	// Connection states
	StatusConnected    = "connected"
	StatusDisconnected = "disconnected"
	StatusReconnecting = "reconnecting"

	// Information states
	StatusInfo    = "info"
	StatusWarning = "warning"
	StatusError   = "error"
	StatusSuccess = "success"
	StatusDebug   = "debug"

	// Process states
	StatusStarted    = "started"
	StatusProcessing = "processing"
	StatusCompleted  = "completed"
	StatusCancelled  = "cancelled"
	StatusPaused     = "paused"
	StatusResumed    = "resumed"

	// Data states
	StatusCreated  = "created"
	StatusUpdated  = "updated"
	StatusDeleted  = "deleted"
	StatusArchived = "archived"

	// System states
	StatusHealthy     = "healthy"
	StatusDegraded    = "degraded"
	StatusMaintenance = "maintenance"
)

// EventLevel represents the severity/importance of an event
type EventLevel int

const (
	LevelDebug EventLevel = iota
	LevelInfo
	LevelWarning
	LevelError
	LevelCritical
)

// EventMetadata contains additional information about the event
type EventMetadata struct {
	Level       EventLevel `json:"level,omitempty"`
	Source      string     `json:"source,omitempty"`
	Category    string     `json:"category,omitempty"`
	RetryCount  int        `json:"retryCount,omitempty"`
	Version     string     `json:"version,omitempty"`
	Environment string     `json:"environment,omitempty"`
}

// Event represents a server-sent event with metadata
type Event struct {
	ID       string         `json:"id"`
	Status   string         `json:"status"`
	Time     time.Time      `json:"time"`
	Data     interface{}    `json:"data,omitempty"`
	Metadata *EventMetadata `json:"metadata,omitempty"`
}

// ProgressEvent represents a progress update
type ProgressEvent struct {
	Percent       int    `json:"percent"`
	CurrentStep   int    `json:"currentStep"`
	TotalSteps    int    `json:"totalSteps"`
	Description   string `json:"description,omitempty"`
	TimeRemaining string `json:"timeRemaining,omitempty"`
}

// AlertEvent represents an alert or notification
type AlertEvent struct {
	Title      string    `json:"title"`
	Message    string    `json:"message"`
	Level      string    `json:"level"`
	ActionURL  string    `json:"actionUrl,omitempty"`
	Expiration time.Time `json:"expiration,omitempty"`
	Time       time.Time `json:"time"`
}

// EventHubInstance is the central hub for managing connections and events.
// Ensure that this is initialized and injected by the application.
var EventHubInstance *EventHub

// Send broadcasts an event to a specific client on a specific path
func Send(path string, clientID int64, data interface{}) {
	if EventHubInstance != nil {
		EventHubInstance.Broadcast(path, clientID, data)
	}
}

// SendWithStatus sends an event with additional status metadata to a specific client on a specific path
func SendWithStatus(path string, clientID int64, status string, data interface{}) {
	event := Event{
		ID:     uuid.New().String(),
		Status: status,
		Time:   time.Now(),
		Data:   data,
	}
	Send(path, clientID, event)
}

// SendWithMetadata sends an event with full metadata to a specific client on a specific path
func SendWithMetadata(path string, clientID int64, status string, data interface{}, metadata *EventMetadata) {
	event := Event{
		ID:       uuid.New().String(),
		Status:   status,
		Time:     time.Now(),
		Data:     data,
		Metadata: metadata,
	}
	Send(path, clientID, event)
}

// SendToPath sends an event to all clients subscribed to a specific path
func SendToPath(path string, data interface{}) {
	if EventHubInstance != nil {
		EventHubInstance.BroadcastPath(path, data)
	}
}

// SendToPathWithStatus sends an event with a status to all clients on a specific path
func SendToPathWithStatus(path string, status string, data interface{}) {
	event := Event{
		ID:     uuid.New().String(),
		Status: status,
		Time:   time.Now(),
		Data:   data,
	}
	SendToPath(path, event)
}

// SendToPathWithMetadata sends an event with metadata to all clients on a specific path
func SendToPathWithMetadata(path string, status string, data interface{}, metadata *EventMetadata) {
	event := Event{
		ID:       uuid.New().String(),
		Status:   status,
		Time:     time.Now(),
		Data:     data,
		Metadata: metadata,
	}
	SendToPath(path, event)
}

// SendProgress sends a progress update event to a specific client on a specific path
func SendProgress(path string, clientID int64, percent, currentStep, totalSteps int, description string) {
	progress := ProgressEvent{
		Percent:     percent,
		CurrentStep: currentStep,
		TotalSteps:  totalSteps,
		Description: description,
	}
	SendWithStatus(path, clientID, StatusProcessing, progress)
}

// SendAlert sends an alert event to a specific client on a specific path
func SendAlert(path string, clientID int64, title, message string, level EventLevel) {
	alert := AlertEvent{
		Title:   title,
		Message: message,
		Level:   getLevelString(level),
		Time:    time.Now(),
	}
	SendWithMetadata(path, clientID, StatusInfo, alert, &EventMetadata{
		Level:    level,
		Category: "alert",
	})
}

// Helper function to convert EventLevel to string
func getLevelString(level EventLevel) string {
	switch level {
	case LevelDebug:
		return "debug"
	case LevelInfo:
		return "info"
	case LevelWarning:
		return "warning"
	case LevelError:
		return "error"
	case LevelCritical:
		return "critical"
	default:
		return "unknown"
	}
}
