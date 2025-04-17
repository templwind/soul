package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Team represents a group of users collaborating.
type Team struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Name    string    `gorm:"size:100;not null"`
	OwnerID uuid.UUID `gorm:"type:uuid;not null;index"` // Foreign key to the User who owns the team

	// --- Relationships ---
	Owner User `gorm:"foreignKey:OwnerID"` // Belongs To User (Owner)
	// Memberships []Membership `gorm:"foreignKey:TeamID"` // Has Many Memberships - Uncomment when Membership model is defined
	// Invitations []Invitation `gorm:"foreignKey:TeamID"` // Has Many Invitations - Uncomment when Invitation model is defined
}

// BeforeCreate hook to generate UUID if not set
func (t *Team) BeforeCreate(tx *gorm.DB) (err error) {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	// Add other validation or default setting logic here if needed
	return
}
