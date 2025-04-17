package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// Plan defines the structure for subscription plans.
type Plan struct {
	ID                  string         `gorm:"primaryKey;size:50"`
	Name                string         `gorm:"size:100;not null"`
	StripePriceID       string         `gorm:"size:100;index"` // Monthly price ID
	Features            datatypes.JSON `gorm:"type:jsonb"`     // Store features as JSON
	PriceMonthly        float64        `gorm:"type:decimal(10,2)"`
	StripePriceIDYearly *string        `gorm:"size:100;index"` // Optional yearly price ID
	PriceYearly         *float64       `gorm:"type:decimal(10,2)"`
	Active              bool           `gorm:"default:true;index"`
	CreatedAt           time.Time      `gorm:"autoCreateTime"`
	UpdatedAt           time.Time      `gorm:"autoUpdateTime"`
	DeletedAt           gorm.DeletedAt `gorm:"index"` // Add soft delete support
}

// Subscription tracks user subscriptions.
type Subscription struct {
	ID                   uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	UserID               uuid.UUID `gorm:"type:uuid;not null;index"`
	PlanID               string    `gorm:"size:50;not null;index"` // Foreign key to Plan.ID
	StripeSubscriptionID string    `gorm:"size:100;uniqueIndex;not null"`
	Status               string    `gorm:"size:50;not null;index"` // e.g., active, past_due, canceled, trialing
	CurrentPeriodStart   time.Time
	CurrentPeriodEnd     time.Time
	CancelAtPeriodEnd    bool           `gorm:"default:false"`
	CreatedAt            time.Time      `gorm:"autoCreateTime"`
	UpdatedAt            time.Time      `gorm:"autoUpdateTime"`
	DeletedAt            gorm.DeletedAt `gorm:"index"` // Add soft delete support

	// --- Relationships ---
	User User `gorm:"foreignKey:UserID"`
	Plan Plan `gorm:"foreignKey:PlanID"`
	// Items []SubscriptionItem `gorm:"foreignKey:SubscriptionID"` // Has Many Items - Uncomment when needed
}

// SubscriptionItem tracks add-ons or specific line items associated with a subscription.
type SubscriptionItem struct {
	ID                       uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	SubscriptionID           uuid.UUID      `gorm:"type:uuid;not null;index"` // Foreign key to Subscription.ID
	StripeSubscriptionItemID string         `gorm:"size:100;uniqueIndex;not null"`
	StripePriceID            string         `gorm:"size:100;not null;index"` // Foreign key to the Stripe Price object for the item
	ItemType                 string         `gorm:"size:50;not null;index"`  // e.g., 'addon', 'usage', 'seat'
	RelatedResourceID        *uuid.UUID     `gorm:"type:uuid;index"`         // Optional link to another resource (e.g., a specific addon instance)
	Quantity                 int            `gorm:"default:1"`
	CreatedAt                time.Time      `gorm:"autoCreateTime"`
	UpdatedAt                time.Time      `gorm:"autoUpdateTime"`
	DeletedAt                gorm.DeletedAt `gorm:"index"` // Add soft delete support

	// --- Relationships ---
	Subscription Subscription `gorm:"foreignKey:SubscriptionID"`
	// PlanItem Plan `gorm:"foreignKey:StripePriceID;references:StripePriceID"` // Potential link back to Plan based on Price ID if needed
}

// Note: Invoice model is omitted for now as per the comment in the original file.
// It can be added later if caching invoice data locally becomes necessary.
