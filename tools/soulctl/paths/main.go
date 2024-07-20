package main

import (
	"fmt"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
)

// collectImports traverses the specified path and collects unique import statements.
func collectImports(path string) ([]string, error) {
	imports := make(map[string]struct{})

	err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(path, ".go") {
			fileImports, err := getImportsFromFile(path)
			if err != nil {
				return err
			}
			for _, imp := range fileImports {
				imports[imp] = struct{}{}
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	var importList []string
	for imp := range imports {
		importList = append(importList, imp)
	}

	return importList, nil
}

// getImportsFromFile parses a Go file and returns its import statements.
func getImportsFromFile(path string) ([]string, error) {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
	if err != nil {
		return nil, err
	}

	var imports []string
	for _, imp := range node.Imports {
		importPath := strings.Trim(imp.Path.Value, `"`)
		imports = append(imports, importPath)
	}

	return imports, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run main.go <path>")
		return
	}
	path := os.Args[1]

	imports, err := collectImports(path)
	if err != nil {
		fmt.Printf("Error collecting imports: %v\n", err)
		return
	}

	fmt.Println("Unique import statements:")
	for _, imp := range imports {
		fmt.Println(imp)
	}
}
