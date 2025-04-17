package moduleinit

import (
	"{{.ServiceName}}/internal/svc"

	"github.com/zeromicro/go-zero/core/logx"
)

// Initializer allows modules to hook into the application lifecycle.
type Initializer interface {
	// Initialize performs module-specific setup after core services are ready.
	Initialize(svcCtx *svc.ServiceContext) error
	// Shutdown performs module-specific cleanup before the application exits.
	Shutdown(svcCtx *svc.ServiceContext) error
	// Name returns the module name for logging purposes.
	Name() string
}

var registeredInitializers []Initializer

// Register adds an initializer to the registry. Called via module's init().
func Register(initializer Initializer) {
	logx.Infof("Registering initializer for module: %s", initializer.Name())
	registeredInitializers = append(registeredInitializers, initializer)
}

// RunInitializers executes the Initialize method for all registered modules.
func RunInitializers(svcCtx *svc.ServiceContext) error {
	logx.Infof("Running initializers for %d registered modules...", len(registeredInitializers))
	for _, initer := range registeredInitializers {
		logx.Infof("Initializing module: %s", initer.Name())
		if err := initer.Initialize(svcCtx); err != nil {
			logx.Errorf("Failed to initialize module %s: %v", initer.Name(), err)
			return err // Fail fast on initialization error
		}
	}
	logx.Info("Finished running module initializers.")
	return nil
}

// RunShutdowns executes the Shutdown method for all registered modules.
func RunShutdowns(svcCtx *svc.ServiceContext) {
	logx.Info("Running shutdowns for registered modules...")
	for _, initer := range registeredInitializers {
		logx.Infof("Shutting down module: %s", initer.Name())
		if err := initer.Shutdown(svcCtx); err != nil {
			logx.Errorf("Error shutting down module %s: %v", initer.Name(), err)
		}
	}
	logx.Info("Finished running module shutdowns.")
}
