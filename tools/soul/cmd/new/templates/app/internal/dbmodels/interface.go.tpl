package dbmodels

import (
	"github.com/zeromicro/go-zero/core/logx"
)

// ModelProvider allows modules to register their GORM models.
type ModelProvider interface {
	// GetModels returns a slice of pointers to GORM model structs.
	GetModels() []interface{}
}

var registeredProviders []ModelProvider

// RegisterProvider adds a module's model provider. Called via module's init().
func RegisterProvider(provider ModelProvider) {
	logx.Infof("Registering model provider: %T", provider)
	registeredProviders = append(registeredProviders, provider)
}

// GetAllModels collects models from all registered providers.
func GetAllModels() []interface{} {
	allModels := []interface{}{}
	logx.Infof("Collecting models from %d registered providers...", len(registeredProviders))
	for _, provider := range registeredProviders {
		moduleModels := provider.GetModels()
		logx.Infof("Provider %T provided %d models.", provider, len(moduleModels))
		allModels = append(allModels, moduleModels...)
	}
	return allModels
}
