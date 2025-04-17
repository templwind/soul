package models

import (
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BlogPostStatus defines the possible states of a blog post.
type BlogPostStatus string

const (
	StatusDraft     BlogPostStatus = "draft"
	StatusPublished BlogPostStatus = "published"
	StatusArchived  BlogPostStatus = "archived"
)

// BlogPost represents an article or entry in the blog.
type BlogPost struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()"`
	CreatedAt time.Time      `gorm:"autoCreateTime"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Title       string         `gorm:"size:255;not null;index"`
	Slug        string         `gorm:"size:255;not null;uniqueIndex"` // URL-friendly identifier
	Content     string         `gorm:"type:text"`                     // Can store Markdown or HTML
	Excerpt     string         `gorm:"type:text"`                     // Short summary
	AuthorID    *uuid.UUID     `gorm:"type:uuid;index"`               // Link to User model (nullable)
	Status      BlogPostStatus `gorm:"size:20;not null;default:draft;index"`
	PublishedAt *time.Time     `gorm:"index"` // Timestamp when the post was published

	// Optional fields
	FeaturedImageURL string `gorm:"size:512"`

	// --- Relationships ---
	Author *User `gorm:"foreignKey:AuthorID"` // Belongs To User (optional)
	// Tags       []*Tag      `gorm:"many2many:blog_post_tags;"`      // Many-to-many with Tag - Uncomment when Tag model is defined
	// Categories []*Category `gorm:"many2many:blog_post_categories;"`  // Many-to-many with Category - Uncomment when Category model is defined
}

// --- Slug Generation ---

var (
	nonAlphanumericRegex = regexp.MustCompile(`[^a-z0-9]+`)
	dashRegex            = regexp.MustCompile(`-{2,}`)
)

// generateSlug creates a URL-friendly slug from a title.
func generateSlug(title string) string {
	lower := strings.ToLower(title)
	noSpecial := nonAlphanumericRegex.ReplaceAllString(lower, "-")
	noMultipleDashes := dashRegex.ReplaceAllString(noSpecial, "-")
	trimmed := strings.Trim(noMultipleDashes, "-")
	// Note: Uniqueness check ideally happens in the handler/logic layer before saving
	// to avoid complex DB lookups within the hook and handle potential race conditions.
	// If a collision occurs, the handler can append a suffix (e.g., "-1", "-2").
	return trimmed
}

// --- Hooks ---

// BeforeSave hook to automatically generate slug if empty and set PublishedAt.
func (p *BlogPost) BeforeSave(tx *gorm.DB) (err error) {
	// Generate slug from title if slug is empty and title is present
	if p.Slug == "" && p.Title != "" {
		p.Slug = generateSlug(p.Title)
		// Consider adding a check in the logic layer to ensure slug uniqueness before calling save.
	}

	// Manage PublishedAt timestamp based on Status changes
	// Check if Status field is actually being changed in this transaction
	if tx.Statement.Changed("Status") {
		if p.Status == StatusPublished {
			// If changing to Published and PublishedAt is not already set
			if p.PublishedAt == nil {
				now := time.Now().UTC() // Use UTC for consistency
				p.PublishedAt = &now
			}
		} else {
			// If changing to any status other than Published, clear PublishedAt
			p.PublishedAt = nil
		}
	} else if p.Status == StatusPublished && p.PublishedAt == nil {
		// Handle case where record is created directly as Published
		now := time.Now().UTC()
		p.PublishedAt = &now
	}

	// Generate UUID if not set (relevant for BeforeCreate)
	if p.ID == uuid.Nil && tx.Statement.Schema != nil && tx.Statement.Schema.PrioritizedPrimaryField != nil && tx.Statement.Schema.PrioritizedPrimaryField.Name == "ID" {
		// This check is more robust for hooks that might run in different contexts
		p.ID = uuid.New()
	}

	return nil
}
