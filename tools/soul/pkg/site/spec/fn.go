package spec

import (
	"fmt"
	"strings"
)

func SetServiceName(spec *SiteSpec) (string, error) {
	if len(spec.Servers) == 0 {
		return "", fmt.Errorf("no server found in site file")
	}

	// get the name
	if strings.TrimSpace(spec.Name) == "" {
		if len(spec.Servers[0].Services) == 0 {
			return "", fmt.Errorf("no service found in site file")
		}

		spec.Name = spec.Servers[0].Services[0].Name
	}

	if strings.TrimSpace(spec.Name) == "" {
		return "", fmt.Errorf("no service name found in site file")
	}

	// return a kabab case name
	return strings.ReplaceAll(spec.Name, " ", "-"), nil
}
