package models

import (
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Category represents a classification for blog posts.
type Category struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Name string `gorm:"size:100;not null;uniqueIndex"`
	Slug string `gorm:"size:100;not null;uniqueIndex"` // URL-friendly identifier

	// --- Relationships ---
	// BlogPosts []*BlogPost `gorm:"many2many:blog_post_categories;"` // Many-to-many with BlogPost - Uncomment when needed
}

// --- Slug Generation ---

// Reusing slug generation logic, potentially move to a shared util package later.
var (
	categoryNonAlphanumericRegex = regexp.MustCompile(`[^a-z0-9]+`) // Renamed regex vars slightly
	categoryDashRegex            = regexp.MustCompile(`-{2,}`)
)

// generateCategorySlug creates a URL-friendly slug from a category name.
func generateCategorySlug(name string) string {
	lower := strings.ToLower(name)
	noSpecial := categoryNonAlphanumericRegex.ReplaceAllString(lower, "-")
	noMultipleDashes := categoryDashRegex.ReplaceAllString(noSpecial, "-")
	trimmed := strings.Trim(noMultipleDashes, "-")
	// Note: Uniqueness check ideally happens in the handler/logic layer.
	return trimmed
}

// --- Hooks ---

// BeforeSave hook to automatically generate slug if empty.
func (c *Category) BeforeSave(tx *gorm.DB) (err error) {
	// Generate slug from name if slug is empty and name is present
	if c.Slug == "" && c.Name != "" {
		c.Slug = generateCategorySlug(c.Name)
		// Consider adding a check in the logic layer to ensure slug uniqueness before calling save.
	}

	// Generate UUID if not set (relevant for BeforeCreate)
	if c.ID == uuid.Nil && tx.Statement.Schema != nil && tx.Statement.Schema.PrioritizedPrimaryField != nil && tx.Statement.Schema.PrioritizedPrimaryField.Name == "ID" {
		c.ID = uuid.New()
	}

	return nil
}
