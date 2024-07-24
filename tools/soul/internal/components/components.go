package components

import (
	"fmt"
	"go/parser"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/afero"
)

// Define the types for project command functions
type projectCmdFuncArgs func(args ...string) error
type projectCmdFuncNoArgs func() error

// RunCmdInProjectDirWithArgs with arguments
func RunCmdInProjectDirWithArgs(projectPath string, fn projectCmdFuncArgs, args ...string) error {
	// get the current directory first
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}
	// change to project directory
	if err := os.Chdir(projectPath); err != nil {
		return err
	}

	defer os.Chdir(cwd) // change back to the original directory

	return fn(args...)
}

// RunCmdInProjectDir without arguments
func RunCmdInProjectDir(projectPath string, fn projectCmdFuncNoArgs) error {
	// get the current directory first
	cwd, err := os.Getwd()
	if err != nil {
		return err
	}
	// change to project directory
	if err := os.Chdir(projectPath); err != nil {
		return err
	}

	defer os.Chdir(cwd) // change back to the original directory

	return fn()
}

// Remaining functions...

func FindComponents(modulesDir string) ([]string, error) {
	var components []string
	componentSet := make(map[string]bool)

	err := filepath.Walk(modulesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (strings.HasSuffix(path, ".go") || strings.HasSuffix(path, ".templ")) {
			fileComponents, err := parseImportsForComponents(path)
			if err != nil {
				fmt.Printf("Error parsing imports for file %s: %v\n", path, err)
				return err
			}
			for _, comp := range fileComponents {
				if !componentSet[comp] {
					componentSet[comp] = true
					components = append(components, comp)
				}
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return components, nil
}

// parseImportsForComponents parses the Go file and returns a list of import paths that match the pattern.
func parseImportsForComponents(filePath string) ([]string, error) {
	var components []string

	// Read the file content
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	// Create a new token file set
	fset := token.NewFileSet()

	// Parse the file
	node, err := parser.ParseFile(fset, "", fileContent, parser.ImportsOnly)
	if err != nil {
		return nil, err
	}

	// Collect relevant import paths
	for _, imp := range node.Imports {
		importPath := strings.Trim(imp.Path.Value, "\"")
		if strings.Contains(importPath, "internal/ui/components/") {
			component := filepath.Base(importPath)
			components = append(components, component)
		}
	}

	return components, nil
}

// ProcessClonedRepo processes the cloned repository.
func ProcessClonedRepo(fs afero.Fs, projectPath, moduleNamespace string) error {
	// Create the project directory
	if err := os.MkdirAll(projectPath, os.ModePerm); err != nil {
		return err
	}

	// Walk through the in-memory filesystem and copy files to the project directory
	return afero.Walk(fs, "/", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		targetPath := filepath.Join(projectPath, path)
		if info.IsDir() {
			return os.MkdirAll(targetPath, info.Mode())
		}

		fileContent, err := afero.ReadFile(fs, path)
		if err != nil {
			return err
		}

		return afero.WriteFile(afero.NewOsFs(), targetPath, fileContent, info.Mode())
	})
}

func RunCommand(command string, args ...string) error {
	cmd := exec.Command(command, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func RunTemplGenerate() error {
	return RunCommand("templ", "generate")
}

func RunGoModInit(args ...string) error {
	if len(args) != 1 {
		return fmt.Errorf("RunGoModInit expects exactly one argument")
	}
	return RunCommand("go", "mod", "init", args[0])
}

func RunGoModTidy() error {
	return RunCommand("go", "mod", "tidy")
}

func RunGitInit() error {
	return RunCommand("git", "init")
}

// CloneRepoToMemory clones the repository into memory using afero.
func CloneRepoToMemory(repoURL string) (afero.Fs, error) {
	// Create a temporary directory for cloning the repository
	tempDir, err := os.MkdirTemp("", "repo-clone-")
	if err != nil {
		return nil, fmt.Errorf("error creating temporary directory: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up the temporary directory when done

	cmd := exec.Command("git", "clone", repoURL, tempDir)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("error cloning repository: %v", err)
	}

	fs := afero.NewMemMapFs()
	err = afero.Walk(afero.NewOsFs(), tempDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(tempDir, path)
		if err != nil {
			return err
		}

		if info.IsDir() {
			return fs.MkdirAll(relPath, info.Mode())
		}

		fileContent, err := afero.ReadFile(afero.NewOsFs(), path)
		if err != nil {
			return err
		}

		return afero.WriteFile(fs, relPath, fileContent, info.Mode())
	})

	return fs, err
}
