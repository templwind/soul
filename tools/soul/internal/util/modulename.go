package util

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// GetModuleName reads the go.mod file in the current directory and extracts the module name.
func GetModuleName(projectPath string) (string, error) {
	file, err := os.Open(filepath.Join(projectPath, "go.mod"))
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "module ") {
			// Extract the module name from the line.
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				return parts[1], nil
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return "", err
	}

	return "", fmt.Errorf("module directive not found in go.mod")
}

// FindGoModPath searches for the go.mod file in the current directory and its parent directories.
func FindGoModPath(startDir string) (string, error) {
	currentDir := startDir
	for {
		// Check if go.mod exists in the current directory
		goModPath := filepath.Join(currentDir, "go.mod")
		if _, err := os.Stat(goModPath); err == nil {
			return goModPath, nil
		} else if !os.IsNotExist(err) {
			// An error other than "not exist"
			return "", err
		}

		// Move to the parent directory
		parentDir := filepath.Dir(currentDir)
		if parentDir == currentDir {
			// Root directory reached without finding go.mod
			return "", os.ErrNotExist
		}
		currentDir = parentDir
	}
}
