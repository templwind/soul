package discovery

import (
	"fmt"
	"os"
	"path/filepath"
)

// DiscoverItems scans the project directory and finds all items of the specified type (components, pages, or modules).
func DiscoverItems(installType string) ([]string, error) {
	var items []string

	// Define the base path based on the install type
	var basePath string
	switch installType {
	case "component", "c":
		basePath = "components"
	case "page", "p":
		basePath = "pages"
	case "module", "m":
		basePath = "modules"
	default:
		return nil, fmt.Errorf("unknown install type: %s", installType)
	}

	// Walk the directory tree to find items
	err := filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			// Skip the base directory itself
			if path == basePath {
				return nil
			}
			// Add the directory name as an item
			relPath, _ := filepath.Rel(basePath, path)
			items = append(items, relPath)
		}
		return nil
	})

	return items, err
}
