package installer

import (
	"fmt"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/afero"
	"github.com/templwind/soul/tools/soul/internal/components"
)

func Execute(opts ...Option) error {
	opt := &InstallOptions{}
	for _, fn := range opts {
		fn(opt)
	}

	if opt.ProcessedComponents == nil {
		opt.ProcessedComponents = make(map[string]bool)
	}

	// Clone the repository into memory
	repoURL := "https://github.com/templwind/soul"
	fs, err := components.CloneRepoToMemory(repoURL)
	if err != nil {
		return fmt.Errorf("error cloning repository: %v", err)
	}

	for _, item := range opt.NameList {
		fmt.Println("Processing item:", item)

		switch opt.InstallType {
		case "component", "c":
			if err := processComponent(fs, item, opt.ProjectNamespace, opt.Framework, opt.Destination, opt.ProcessedComponents); err != nil {
				fmt.Println("Error processing component:", item)
			}
		case "page", "p":
			if err := processPage(fs, item, opt.ProjectNamespace, opt.Framework, opt.Destination, opt.NewName, opt.ProcessedComponents); err != nil {
				fmt.Println("Error processing page:", item)
			}
		case "module", "m":
			if err := processModule(fs, item, opt.ProjectNamespace, opt.Framework, opt.Destination, opt.ProcessedComponents); err != nil {
				fmt.Println("Error processing module:", item)
			}
		default:
			return fmt.Errorf("unknown install type: %s", opt.InstallType)
		}
	}

	return nil
}

func processComponent(fs afero.Fs, component, projectNamespace, framework, destination string, processedComponents map[string]bool) error {
	if processedComponents[component] {
		return nil
	}

	componentPath := fmt.Sprintf("components/%s", component)
	componentDest := filepath.Join(destination, componentPath)

	fmt.Println("Target Destination:", componentDest)
	// Check if the component directory already exists
	if _, err := os.Stat(componentDest); err == nil {
		fmt.Printf("Component directory %s already exists. Skipping installation.\n", componentDest)
		return nil
	}

	// Ensure the destination directory exists
	if err := os.MkdirAll(componentDest, os.ModePerm); err != nil {
		return fmt.Errorf("error creating destination directory: %v", err)
	}

	// Fetch the component files from the in-memory repository
	files, err := fetchFilesFromRepo(fs, componentPath)
	if err != nil {
		return fmt.Errorf("error fetching files from repository: %v", err)
	}

	// Mark this component as processed
	processedComponents[component] = true

	// Download and save each file to the destination directory
	for _, file := range files {
		fmt.Println("Found file:", file)

		err := downloadAndSaveFile(fs, file, componentDest)
		if err != nil {
			fmt.Printf("Error downloading file %s: %v\n", file, err)
			continue
		}

		// Parse and rewrite import paths
		if filepath.Ext(file) == ".go" || filepath.Ext(file) == ".templ" {
			err := rewriteImports(filepath.Join(componentDest, filepath.Base(file)), componentDest, projectNamespace)
			if err != nil {
				fmt.Printf("Error rewriting imports for file %s: %v\n", file, err)
				continue
			}

			// Parse the Go file for additional dependencies
			imports, err := ParseGoFile(filepath.Join(componentDest, file))
			if err != nil {
				fmt.Printf("Error parsing file %s: %v\n", file, err)
				continue
			}

			for _, imp := range imports {
				if strings.HasPrefix(imp, "github.com/templwind/soulcomponents/") {
					subComponent := strings.TrimPrefix(imp, "github.com/templwind/soulcomponents/")
					fmt.Println("Found sub-component:", subComponent)

					if err := processComponent(fs, subComponent, projectNamespace, framework, destination, processedComponents); err != nil {
						fmt.Printf("Error processing sub-component %s: %v\n", subComponent, err)
						continue
					}
				}
			}
		}
	}

	return nil
}

func rewriteImports(filePath, componentDest, projectNamespace string) error {
	// Read the file content
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("could not read file: %w", err)
	}

	fmt.Println("Rewriting imports for file:", filePath)
	fmt.Println("componentDest:", filepath.Dir(componentDest))

	// Parse the file to get the imports
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filePath, fileContent, parser.ImportsOnly)
	if err != nil {
		return fmt.Errorf("could not parse file: %w", err)
	}

	// Rewrite import paths
	for _, imp := range node.Imports {
		importPath := strings.Trim(imp.Path.Value, "\"")
		fmt.Println("Found import:", importPath, strings.HasPrefix(importPath, "github.com/templwind/soul"))
		if strings.HasPrefix(importPath, "github.com/templwind/soulcomponents") {
			newImportFilePath := strings.TrimPrefix(importPath, "github.com/templwind/soulcomponents/")
			// replace multiple // with a single /
			newImportFilePath = strings.ReplaceAll(newImportFilePath, "//", "/")
			newImportPath := fmt.Sprintf("%s/%s/%s", projectNamespace, filepath.Dir(componentDest), newImportFilePath)
			fileContent = []byte(strings.ReplaceAll(string(fileContent), importPath, newImportPath))
			fmt.Println("Rewrote import:", importPath, newImportPath)
		}

		fmt.Println("Finished import:", importPath)
	}

	// Write the updated content back to the file
	err = os.WriteFile(filePath, fileContent, 0644)
	if err != nil {
		return fmt.Errorf("could not write file: %w", err)
	}

	return nil
}

func processPage(fs afero.Fs, page, projectNamespace, framework, destination, newName string, processedComponents map[string]bool) error {
	pagePath := fmt.Sprintf("pages/%s", page)
	pageDest := filepath.Join(destination, newName)

	fmt.Println("Target Destination:", pageDest)
	// Ensure the destination directory exists
	if err := os.MkdirAll(pageDest, os.ModePerm); err != nil {
		return fmt.Errorf("error creating destination directory: %v", err)
	}

	// Fetch the page files from the in-memory repository
	files, err := fetchFilesFromRepo(fs, pagePath)
	if err != nil {
		return fmt.Errorf("error fetching files from repository: %v", err)
	}

	// Download and save each file to the destination directory
	for _, file := range files {
		fmt.Println("Found file:", file)

		err := downloadAndSaveFile(fs, file, pageDest)
		if err != nil {
			fmt.Printf("Error downloading file %s: %v\n", file, err)
			continue
		}

		// Parse the Go file for additional dependencies
		if filepath.Ext(file) == ".go" {
			imports, err := ParseGoFile(filepath.Join(pageDest, file))
			if err != nil {
				fmt.Printf("Error parsing file %s: %v\n", file, err)
				continue
			}

			for _, imp := range imports {
				if strings.HasPrefix(imp, "github.com/templwind/soulcomponents/") {
					subComponent := strings.TrimPrefix(imp, "github.com/templwind/soulcomponents/")
					if err := processComponent(fs, subComponent, projectNamespace, framework, destination, processedComponents); err != nil {
						fmt.Printf("Error processing sub-component %s: %v\n", subComponent, err)
						continue
					}
				}
			}
		}
	}

	return nil
}

func processModule(fs afero.Fs, module, projectNamespace, framework, destination string, processedComponents map[string]bool) error {
	modulePath := fmt.Sprintf("modules/%s", module)
	moduleDest := filepath.Join(destination, modulePath)

	fmt.Println("Target Destination:", moduleDest)
	// Ensure the destination directory exists
	if err := os.MkdirAll(moduleDest, os.ModePerm); err != nil {
		return fmt.Errorf("error creating destination directory: %v", err)
	}

	// Fetch the module files from the in-memory repository
	files, err := fetchFilesFromRepo(fs, modulePath)
	if err != nil {
		return fmt.Errorf("error fetching files from repository: %v", err)
	}

	// Download and save each file to the destination directory
	for _, file := range files {
		fmt.Println("Found file:", file)

		err := downloadAndSaveFile(fs, file, moduleDest)
		if err != nil {
			fmt.Printf("Error downloading file %s: %v\n", file, err)
			continue
		}

		// Parse the Go file for additional dependencies
		if filepath.Ext(file) == ".go" {
			imports, err := ParseGoFile(filepath.Join(moduleDest, file))
			if err != nil {
				fmt.Printf("Error parsing file %s: %v\n", file, err)
				continue
			}

			for _, imp := range imports {
				if strings.HasPrefix(imp, "github.com/templwind/soulcomponents/") {
					subComponent := strings.TrimPrefix(imp, "github.com/templwind/soulcomponents/")
					if err := processComponent(fs, subComponent, projectNamespace, framework, destination, processedComponents); err != nil {
						fmt.Printf("Error processing sub-component %s: %v\n", subComponent, err)
						continue
					}
				}
			}
		}
	}

	return nil
}

func fetchFilesFromRepo(fs afero.Fs, path string) ([]string, error) {
	var files []string
	err := afero.Walk(fs, path, func(filePath string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			files = append(files, filePath)
		}
		return nil
	})
	return files, err
}

func downloadAndSaveFile(fs afero.Fs, file, destination string) error {
	fileContent, err := afero.ReadFile(fs, file)
	if err != nil {
		return err
	}

	destPath := filepath.Join(destination, filepath.Base(file))
	parentDir := filepath.Dir(destPath)

	// Ensure the directory structure exists
	if err := os.MkdirAll(parentDir, os.ModePerm); err != nil {
		return err
	}

	return afero.WriteFile(afero.NewOsFs(), destPath, fileContent, 0644)
}

func ParseGoFile(filePath string) ([]string, error) {
	// Read the file content
	fileContent, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("could not read file: %w", err)
	}

	// Create a new token file set
	fset := token.NewFileSet()

	// Parse the file
	node, err := parser.ParseFile(fset, "", fileContent, parser.ImportsOnly)
	if err != nil {
		return nil, fmt.Errorf("could not parse file: %w", err)
	}

	var imports []string
	for _, imp := range node.Imports {
		importPath := strings.Trim(imp.Path.Value, "\"")
		imports = append(imports, importPath)
	}

	return imports, nil
}
