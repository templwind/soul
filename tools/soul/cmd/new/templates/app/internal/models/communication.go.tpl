package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	_ "github.com/lib/pq" // Uncomment if needed for Tags array handling
)

// CommunicationType represents the type of communication
type CommunicationType string

const (
	CommunicationTypeEmail CommunicationType = "email"
	CommunicationTypeNote  CommunicationType = "note" // e.g., an internal note added by an admin
)

// Communication represents a record of communication involving a user, often initiated by an admin.
type Communication struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	// The user this communication is about/to
	UserID uuid.UUID `gorm:"type:uuid;not null;index"`

	// The admin who sent/created this communication (nullable if system-generated?)
	// Consider if AdminID should be nullable depending on use cases. Assuming not null for now.
	AdminID uuid.UUID `gorm:"type:uuid;not null;index"`

	Type     CommunicationType `gorm:"type:varchar(20);not null;index"`
	Subject  string            `gorm:"type:varchar(255)"` // Subject might be optional for notes
	Body     string            `gorm:"type:text;not null"`
	Template string            `gorm:"type:varchar(50)"` // Optional email template identifier

	// --- Fields primarily for Email type ---
	Status    string     `gorm:"type:varchar(20);index"` // e.g., sent, failed, scheduled, delivered, opened
	SentAt    *time.Time `gorm:"index"`                  // Timestamp when sending was initiated/completed
	ErrorInfo string     `gorm:"type:text"`              // Store error details if sending failed

	// --- Optional metadata ---
	// Using JSONB for tags might be more flexible across DBs than text[]
	// Tags datatypes.JSON `gorm:"type:jsonb"`
	// Or keep as text array if definitely PostgreSQL:
	// Tags pq.StringArray `gorm:"type:text[]"` // Requires importing "github.com/lib/pq"

	// --- Relationships ---
	User  User `gorm:"foreignKey:UserID"`
	Admin User `gorm:"foreignKey:AdminID"` // Assumes Admins are also Users
}

// BeforeCreate hook to generate UUID if not set
func (c *Communication) BeforeCreate(tx *gorm.DB) (err error) {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}
