package models

import (
	"gorm.io/gorm"
)

// Customer represents a customer entity in the Agentic Customer Service module.
type Customer struct {
	gorm.Model
	Name  string
	Email string
	Phone string
}

// ModelProvider implements dbmodels.ModelProvider for this module.
type ModelProvider struct{}

// GetModels returns the list of GORM models for this module.
func (p *ModelProvider) GetModels() []interface{} {
	return []interface{}{
		&Customer{},
	}
}
