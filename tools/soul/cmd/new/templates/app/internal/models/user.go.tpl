package models

import (
	"crypto/rand"
	"encoding/hex"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// SystemRole defines global roles within the application.
type SystemRole string

const (
	SystemRoleAdmin SystemRole = "admin" // Can access admin interface
	SystemRoleUser  SystemRole = "user"  // Standard user
)

// AccountStatus defines the possible states of a user account.
type AccountStatus string

const (
	AccountStatusActive    AccountStatus = "active"
	AccountStatusSuspended AccountStatus = "suspended"
	// Add other statuses like "pending_verification", "deactivated" if needed
)

// User represents a user in the system mapped to the database schema.
type User struct {
	ID                     uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	Email                  string         `gorm:"uniqueIndex;not null;size:255"` // Added size limit
	Password               string         `gorm:"not null"`                      // Internal field
	CreatedAt              time.Time      `gorm:"autoCreateTime"`                // GORM handles this
	UpdatedAt              time.Time      `gorm:"autoUpdateTime"`                // GORM handles this
	DeletedAt              gorm.DeletedAt `gorm:"index"`                         // Support soft deletes
	ApiKey                 string         `gorm:"uniqueIndex;size:64"`
	PasswordResetToken     *string        `gorm:"index;size:64"`                   // Nullable password reset token
	PasswordResetExpiresAt *time.Time     ``                                       // Nullable expiry time for the token
	Plan                   string         `gorm:"not null;default:'free';size:50"` // Increased size slightly
	StripeCustomerID       *string        `gorm:"size:100;uniqueIndex"`            // Nullable Stripe Customer ID
	DefaultSubdomain       string         `gorm:"uniqueIndex;size:100"`
	Name                   *string        `gorm:"size:100"`                                   // User's full name (nullable)
	Role                   SystemRole     `gorm:"type:varchar(20);not null;default:'user'"`   // User's global system role
	AccountStatus          AccountStatus  `gorm:"type:varchar(20);not null;default:'active'"` // User account status

	// --- Associations ---
	// Define associations here if needed, e.g.:
	// Subscriptions []Subscription `gorm:"foreignKey:UserID"`
	// Memberships   []Membership   `gorm:"foreignKey:UserID"`
	// Teams         []Team         `gorm:"many2many:team_memberships;"` // Example many2many

	// Add other fields as needed: IsVerified, LastLoginAt, etc.
}

// SetPassword hashes the given password and sets it on the user model
func (u *User) SetPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.Password = string(hashedPassword)
	return nil
}

// CheckPassword compares the given password with the hashed password stored for the user
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

// FindUserByID retrieves a user by their UUID from the database.
func FindUserByID(db *gorm.DB, id uuid.UUID) (*User, error) {
	var user User
	err := db.Where("id = ?", id).First(&user).Error
	if err != nil {
		// Consider returning specific errors like gorm.ErrRecordNotFound
		return nil, err
	}
	return &user, nil
}

// GenerateAPIKey creates a secure random API key (e.g., 64 hex characters)
// Note: This might be better placed in a utility/service package if used elsewhere.
func GenerateAPIKey() (string, error) {
	bytes := make([]byte, 32) // 32 bytes = 256 bits
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// BeforeCreate hook to generate API key if not present
func (u *User) BeforeCreate(tx *gorm.DB) (err error) {
	if u.ID == uuid.Nil {
		u.ID = uuid.New() // Generate UUID if not set
	}
	if u.ApiKey == "" {
		apiKey, err := GenerateAPIKey()
		if err != nil {
			return err
		}
		u.ApiKey = apiKey
	}
	// You might want to generate DefaultSubdomain here too if it's meant to be random
	return
}
