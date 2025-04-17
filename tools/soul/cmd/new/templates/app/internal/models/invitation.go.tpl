package models

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// InvitationStatus defines the possible states of an invitation.
type InvitationStatus string

const (
	StatusPending  InvitationStatus = "pending"
	StatusAccepted InvitationStatus = "accepted"
	StatusDeclined InvitationStatus = "declined"
	StatusExpired  InvitationStatus = "expired"
)

// Invitation represents a request for a user (identified by email) to join a team.
type Invitation struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Email     string           `gorm:"size:255;not null;index"`                   // Email of the invited user
	TeamID    uuid.UUID        `gorm:"type:uuid;not null;index"`                  // Team they are invited to
	InviterID uuid.UUID        `gorm:"type:uuid;not null;index"`                  // User who sent the invitation
	Role      Role             `gorm:"type:varchar(20);not null"`                 // Role offered (cannot invite owners)
	Token     string           `gorm:"size:64;uniqueIndex;not null"`              // Secure, unique token for the invitation link
	Status    InvitationStatus `gorm:"type:varchar(20);not null;default:pending"` // Current status of the invitation
	ExpiresAt time.Time        `gorm:"not null"`                                  // When the invitation expires

	// --- Relationships ---
	Team    Team `gorm:"foreignKey:TeamID"`    // Belongs To Team
	Inviter User `gorm:"foreignKey:InviterID"` // Belongs To User (Inviter)
}

// GenerateInvitationToken creates a secure random token.
// Moved out of BeforeCreate for potential reuse, though could stay inline.
func GenerateInvitationToken() (string, error) {
	bytes := make([]byte, 32) // 32 bytes = 256 bits
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// BeforeCreate hook to generate a unique token, set expiry, default status, and validate role.
func (inv *Invitation) BeforeCreate(tx *gorm.DB) (err error) {
	if inv.ID == uuid.Nil {
		inv.ID = uuid.New()
	}

	// Generate secure random token if not already set (e.g., for testing)
	if inv.Token == "" {
		token, err := GenerateInvitationToken()
		if err != nil {
			return err // Propagate error
		}
		inv.Token = token
	}

	// Set default expiry (e.g., 7 days from now) if not set
	if inv.ExpiresAt.IsZero() {
		inv.ExpiresAt = time.Now().Add(7 * 24 * time.Hour)
	}

	// Set default status if not set
	if inv.Status == "" {
		inv.Status = StatusPending
	}

	// Ensure invited role is not owner
	if inv.Role == RoleOwner {
		return errors.New("cannot invite user as owner")
	}
	// Ensure role is valid
	switch inv.Role {
	case RoleAdmin, RoleMember:
		// Valid roles for invitation
	default:
		return errors.New("invalid role for invitation")
	}

	return nil
}
