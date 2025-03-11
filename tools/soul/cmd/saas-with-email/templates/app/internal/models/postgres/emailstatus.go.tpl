package models

import (
	"database/sql/driver"
	"errors"
	"fmt"
)

// EmailStatus represents the status of an email.
type EmailStatus string

const (
	EmailStatusQueued       EmailStatus = "queued"
	EmailStatusSent         EmailStatus = "sent"
	EmailStatusDelivered    EmailStatus = "delivered"
	EmailStatusOpened       EmailStatus = "opened"
	EmailStatusClicked      EmailStatus = "clicked"
	EmailStatusSoftBounced  EmailStatus = "soft_bounced"
	EmailStatusHardBounced  EmailStatus = "hard_bounced"
	EmailStatusComplained   EmailStatus = "complained"
	EmailStatusUnsubscribed EmailStatus = "unsubscribed"
	EmailStatusFailed       EmailStatus = "failed"
	EmailStatusDeferred     EmailStatus = "deferred"
)

// String returns the string representation of the EmailStatus.
func (e EmailStatus) String() string {
	return string(e)
}

// Valid validates the EmailStatus value.
func (e EmailStatus) Valid() error {
	switch e {
	case EmailStatusQueued, EmailStatusSent, EmailStatusDelivered, EmailStatusOpened, EmailStatusClicked,
		EmailStatusSoftBounced, EmailStatusHardBounced, EmailStatusComplained, EmailStatusUnsubscribed,
		EmailStatusFailed, EmailStatusDeferred:
		return nil
	default:
		return fmt.Errorf("invalid EmailStatus: %s", e)
	}
}

// Scan implements the Scanner interface for database deserialization.
func (e *EmailStatus) Scan(value interface{}) error {
	strValue, ok := value.(string)
	if !ok {
		return errors.New("invalid type assertion to string for EmailStatus")
	}
	*e = EmailStatus(strValue)
	return e.Valid()
}

// Value implements the driver Valuer interface for database serialization.
func (e EmailStatus) Value() (driver.Value, error) {
	return string(e), nil
}
