package starter

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/templwind/templwind/tools/soul/internal/components"
	"github.com/templwind/templwind/tools/soul/templates"
)

var baseTplPath = "starter"

// Execute handles the logic to starter a new project at the specified path.
func Execute(projectPath, moduleNamespace string, framework string) {
	if !isEmptyDirectory(projectPath) {
		fmt.Printf("Error: Project %s already exists\n", projectPath)
		return
	}

	fullProjectPath, err := filepath.Abs(projectPath)
	if err != nil {
		fmt.Printf("Error determining full path: %v\n", err)
		return
	}

	fmt.Println("Initializing project in", fullProjectPath)

	if err := os.MkdirAll(fullProjectPath, os.ModePerm); err != nil {
		fmt.Printf("Error creating project directory: %v\n", err)
		return
	}

	// this must be first
	if err := components.RunCmdInProjectDirWithArgs(fullProjectPath, initializeProjectWithVite, "vanilla-ts"); err != nil {
		fmt.Printf("Error creating Vite project: %v\n", err)
		return
	}

	if err := components.RunCmdInProjectDirWithArgs(fullProjectPath, components.RunGoModInit, moduleNamespace); err != nil {
		fmt.Printf("Error initializing Go module: %v\n", err)
		return
	}

	if err := components.RunCmdInProjectDir(fullProjectPath, installJavaScriptDependencies); err != nil {
		fmt.Printf("Error installing front-end dependencies: %v\n", err)
		return
	}

	if err := components.RunCmdInProjectDir(fullProjectPath, initializeTailwindCSS); err != nil {
		fmt.Printf("Error initializing Tailwind CSS: %v\n", err)
		return
	}

	cleanViteProject(fullProjectPath)

	// Create or update required files
	funcs := fileHandlersFromTpls(baseTplPath)
	for _, handler := range funcs {
		tplPath := filepath.Dir(handler.Path)
		if err := os.MkdirAll(tplPath, os.ModePerm); err != nil {
			fmt.Printf("Failed to create directory %s: %v\n", tplPath, err)
			return
		}

		if err := handler.Handle(fullProjectPath, handler.Path, framework); err != nil {
			fmt.Printf("Error handling %s: %v\n", handler.Path, err)
			return
		}
	}

	if err := createReadme(fullProjectPath); err != nil {
		fmt.Printf("Failed to create README.md: %v\n", err)
		return
	}

	fmt.Println("Project initialized successfully in", fullProjectPath)
}

func isEmptyDirectory(path string) bool {

	fmt.Println("Checking if directory is empty:", path)
	if _, err := os.Stat(path); err == nil {
		fmt.Println("Directory exists")
		if files, err := os.ReadDir(path); err == nil && len(files) > 0 {
			// list the files that are in the directory
			fmt.Println("\nDirectory is not empty")
			fmt.Println()
			for _, file := range files {
				fmt.Println("Found: " + file.Name())
			}
			fmt.Println()
			return false
		}
	}
	return true
}

func initializeProjectWithVite(args ...string) error {
	if len(args) != 1 {
		return fmt.Errorf("initializeProjectWithVite expects exactly one argument")
	}
	return components.RunCommand("pnpm", "create", "vite@latest", ".", "---", "--template", args[0])
}

func installJavaScriptDependencies() error {
	return components.RunCommand("pnpm", "install", "-D", "tailwindcss@latest", "postcss@latest", "autoprefixer@latest", "sass@latest", "htmx.org")
}

func initializeTailwindCSS() error {
	return components.RunCommand("npx", "tailwindcss", "init", "-p")
}

func cleanViteProject(fullProjectPath string) {
	toRemove := []string{
		"public",
		"src/*",
	}
	for _, dir := range toRemove {
		files, err := filepath.Glob(filepath.Join(fullProjectPath, dir))
		if err != nil {
			fmt.Printf("Error globbing %s: %v\n", dir, err)
			return
		}
		for _, file := range files {
			if !strings.Contains(file, "d.ts") {
				if err := os.RemoveAll(file); err != nil {
					fmt.Printf("Error removing %s: %v\n", file, err)
					return
				}
			}
		}
	}
}

func createReadme(fullProjectPath string) error {
	readmePath := filepath.Join(fullProjectPath, "README.md")
	readmeContent := []byte("# Project\n\nWelcome to your new project!")
	return os.WriteFile(readmePath, readmeContent, 0644)
}

type handleFunc func(string, string, string) error

type fileHandler struct {
	Path   string
	Handle handleFunc
}

// Create file handlers from *.tpl files
func fileHandlersFromTpls(rootPath string) map[string]fileHandler {
	tplFiles, err := templates.GetTplFiles(rootPath)
	if err != nil {
		fmt.Printf("Error walking the path: %v\n", err)
		return nil
	}

	handlers := make(map[string]fileHandler)
	for _, file := range tplFiles {
		relativePath, err := filepath.Rel(rootPath, file)
		if err != nil {
			fmt.Printf("Error getting relative path: %v\n", err)
			continue
		}

		handlers[relativePath] = fileHandler{
			Path:   relativePath,
			Handle: createFileFromTpl,
		}
	}

	// Add custom handlers if any
	for _, handler := range customFileHandlers() {
		handlers[handler.Path] = handler
	}

	return handlers
}

// Custom file handlers
func customFileHandlers() []fileHandler {
	return []fileHandler{
		{Path: "vite.config.ts", Handle: createViteConfig},
		{Path: "package.json", Handle: updatePackageJSON},
	}
}
