package models

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Role defines the possible roles a user can have within a team.
type Role string

const (
	RoleOwner  Role = "owner"  // Can manage billing, team settings, and members
	RoleAdmin  Role = "admin"  // Can manage members and team settings (but not billing)
	RoleMember Role = "member" // Standard member access
)

// Membership links a User to a Team with a specific Role.
type Membership struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	UserID uuid.UUID `gorm:"type:uuid;uniqueIndex:idx_user_team;not null"` // Part of composite unique index
	TeamID uuid.UUID `gorm:"type:uuid;uniqueIndex:idx_user_team;not null"` // Part of composite unique index
	Role   Role      `gorm:"type:varchar(20);not null"`

	// --- Relationships ---
	User User `gorm:"foreignKey:UserID"` // Belongs To User
	Team Team `gorm:"foreignKey:TeamID"` // Belongs To Team
}

// BeforeCreate hook to generate UUID if not set and validate Role
func (m *Membership) BeforeCreate(tx *gorm.DB) (err error) {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	// Validate Role
	switch m.Role {
	case RoleOwner, RoleAdmin, RoleMember:
		// Valid role
	default:
		return errors.New("invalid membership role")
	}
	return nil
}

// BeforeUpdate hook to validate Role on update
func (m *Membership) BeforeUpdate(tx *gorm.DB) (err error) {
	// Validate Role if it's being changed
	if tx.Statement.Changed("Role") {
		switch m.Role {
		case RoleOwner, RoleAdmin, RoleMember:
			// Valid role
		default:
			return errors.New("invalid membership role")
		}
	}
	return nil
}
