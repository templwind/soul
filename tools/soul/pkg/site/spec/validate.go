package spec

import (
	"errors"
	"fmt"
)

// Validate checks the integrity of the SiteSpec
func (spec *SiteSpec) Validate() error {
	if spec.Name == "" {
		return errors.New("spec name is required")
	}
	if len(spec.Types) == 0 {
		return errors.New("at least one type is required")
	}
	if len(spec.Servers) == 0 {
		return errors.New("at least one server is required")
	}

	for _, server := range spec.Servers {
		if len(server.Services) == 0 {
			return fmt.Errorf("server %s must have at least one service", server.Annotation.Properties["name"])
		}
		for _, service := range server.Services {
			if len(service.Handlers) == 0 {
				return fmt.Errorf("service %s must have at least one handler", service.Name)
			}
			for _, handler := range service.Handlers {
				if handler.Name == "" {
					return fmt.Errorf("handler in service %s must have a name", service.Name)
				}
				if len(handler.Methods) == 0 {
					return fmt.Errorf("handler %s in service %s must have a method", handler.Name, service.Name)
				}
				for _, method := range handler.Methods {

					// b, _ := json.MarshalIndent(handler, "", "  ")
					// fmt.Println("handler", string(b))

					// fmt.Printf("METHOD: %#v", handler)
					if method.Route == "" {
						return fmt.Errorf("method in handler %s in service %s must have a route", handler.Name, service.Name)
					}
				}
			}
		}
	}
	return nil
}
