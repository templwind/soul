package models

import (
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Tag represents a keyword or label associated with blog posts.
type Tag struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Name string `gorm:"size:100;not null;uniqueIndex"`
	Slug string `gorm:"size:100;not null;uniqueIndex"` // URL-friendly identifier

	// --- Relationships ---
	// BlogPosts []*BlogPost `gorm:"many2many:blog_post_tags;"` // Many-to-many with BlogPost - Uncomment when needed
}

// --- Slug Generation ---

// Reusing slug generation logic, potentially move to a shared util package later.
var (
	tagNonAlphanumericRegex = regexp.MustCompile(`[^a-z0-9]+`) // Renamed regex vars slightly
	tagDashRegex            = regexp.MustCompile(`-{2,}`)
)

// generateTagSlug creates a URL-friendly slug from a tag name.
func generateTagSlug(name string) string {
	lower := strings.ToLower(name)
	noSpecial := tagNonAlphanumericRegex.ReplaceAllString(lower, "-")
	noMultipleDashes := tagDashRegex.ReplaceAllString(noSpecial, "-")
	trimmed := strings.Trim(noMultipleDashes, "-")
	// Note: Uniqueness check ideally happens in the handler/logic layer.
	return trimmed
}

// --- Hooks ---

// BeforeSave hook to automatically generate slug if empty.
func (t *Tag) BeforeSave(tx *gorm.DB) (err error) {
	// Generate slug from name if slug is empty and name is present
	if t.Slug == "" && t.Name != "" {
		t.Slug = generateTagSlug(t.Name)
		// Consider adding a check in the logic layer to ensure slug uniqueness before calling save.
	}

	// Generate UUID if not set (relevant for BeforeCreate)
	if t.ID == uuid.Nil && tx.Statement.Schema != nil && tx.Statement.Schema.PrioritizedPrimaryField != nil && tx.Statement.Schema.PrioritizedPrimaryField.Name == "ID" {
		t.ID = uuid.New()
	}

	return nil
}
