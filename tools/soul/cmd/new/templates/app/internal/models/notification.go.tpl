package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Notification represents a message or alert for a user.
type Notification struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime;index"` // Added index for sorting
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	UserID uuid.UUID  `gorm:"type:uuid;index;not null"` // The user this notification is for
	Type   string     `gorm:"size:50;index"`            // Category/type (e.g., 'billing', 'security', 'team', 'general')
	Title  string     `gorm:"size:255;not null"`
	Body   string     `gorm:"type:text"`           // Longer description or details
	IsRead bool       `gorm:"default:false;index"` // Whether the user has read the notification
	ReadAt *time.Time `gorm:"index"`               // Timestamp when it was marked as read

	// Optional: Link to related resource (e.g., team ID, invoice ID)
	// RelatedResourceType string `gorm:"size:50;index"`
	// RelatedResourceID   string `gorm:"size:100;index"` // Use string for flexibility (UUIDs, IDs, etc.)

	// --- Relationships ---
	User User `gorm:"foreignKey:UserID"` // Belongs To User
}

// BeforeCreate hook to generate UUID if not set
func (n *Notification) BeforeCreate(tx *gorm.DB) (err error) {
	if n.ID == uuid.Nil {
		n.ID = uuid.New()
	}
	return nil
}
