package init

import (
	"{{.ServiceName}}/internal/dbmodels"
	"{{.ServiceName}}/internal/moduleinit"
	"{{.ServiceName}}/internal/modules/sample/models"
	"{{.ServiceName}}/internal/svc"
)

// ModuleInitializer implements moduleinit.Initializer interface (optional)
type ModuleInitializer struct{}

func (m *ModuleInitializer) Initialize(svcCtx *svc.ServiceContext) error {
	// Add module-specific initialization logic here if needed
	return nil
}

func (m *ModuleInitializer) Shutdown(svcCtx *svc.ServiceContext) error {
	// Add module-specific shutdown logic here if needed
	return nil
}

func (m *ModuleInitializer) Name() string {
	return "agentic_cs"
}

func init() {
	// Register GORM models
	dbmodels.RegisterProvider(&models.ModelProvider{})

	// Register module initializer
	moduleinit.Register(&ModuleInitializer{})
}
