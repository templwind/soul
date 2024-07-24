package saas

import (
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
	"github.com/zeromicro/go-zero/tools/goctl/pkg/golang"
)

//go:embed templates/*
var templatesFS embed.FS

type SaaSBuilder struct {
	Dir            string
	ModuleName     string
	DB             types.DBType
	Router         types.RouterType
	Spec           *spec.SiteSpec
	Data           map[string]any
	CustomFuncs    map[string]customFunc
	RenameFiles    map[string]string
	IgnoreFiles    map[string]bool
	IgnorePaths    map[string]bool
	OverwriteFiles map[string]bool
}

type customFunc func(saasBuilder *SaaSBuilder) error

func NewSaaSBuilder(dir, moduleName string, db types.DBType, router types.RouterType, siteSpec *spec.SiteSpec) *SaaSBuilder {
	return &SaaSBuilder{
		Dir:            dir,
		ModuleName:     moduleName,
		DB:             db,
		Router:         router,
		Spec:           siteSpec,
		Data:           make(map[string]any),
		CustomFuncs:    make(map[string]customFunc),
		RenameFiles:    make(map[string]string),
		IgnoreFiles:    map[string]bool{"handler.go.tpl": true},
		IgnorePaths:    map[string]bool{"templates/internal/handler/": true},
		OverwriteFiles: make(map[string]bool),
	}
}

func (sb *SaaSBuilder) WithData(data map[string]any) {
	for k, v := range data {
		sb.Data[k] = v
	}
}

func (sb *SaaSBuilder) WithOverwriteFiles(files ...string) {
	for _, file := range files {
		sb.OverwriteFiles[file] = true
	}
}

func (sb *SaaSBuilder) WithOverwriteFile(file string) {
	sb.OverwriteFiles[file] = true
}

func (sb *SaaSBuilder) WithIgnoreFiles(files ...string) {
	for _, file := range files {
		sb.IgnoreFiles[file] = true
	}
}

func (sb *SaaSBuilder) WithIgnoreFile(file string) {
	sb.IgnoreFiles[file] = true
}

func (sb *SaaSBuilder) WithRenameFiles(files map[string]string) {
	for k, v := range files {
		sb.RenameFiles[k] = v
	}
}

func (sb *SaaSBuilder) WithRenameFile(oldName, newName string) {
	sb.RenameFiles[oldName] = newName
}

func (sb *SaaSBuilder) WithIgnorePaths(paths ...string) {
	for _, path := range paths {
		sb.IgnorePaths[path] = true
	}
}

func (sb *SaaSBuilder) WithIgnorePath(path string) {
	sb.IgnorePaths[path] = true
}

func (sb *SaaSBuilder) WithCustomFunc(filePath string, fn customFunc) {
	sb.CustomFuncs[filePath] = fn
}

type fileGenConfig struct {
	subdir       string
	templateFile string
	data         map[string]any
	customFunc   customFunc
}

func (sb *SaaSBuilder) shouldIgnore(path string) bool {
	path = strings.TrimPrefix(path, "templates/")
	// fmt.Println("Checking", path, sb.IgnorePaths[path])

	for ignorePath := range sb.IgnorePaths {
		// fmt.Println("Checking", path, "against", ignorePath)
		ignorePath = strings.TrimPrefix(ignorePath, "templates/")
		if strings.HasPrefix(path, ignorePath) {
			// fmt.Println("Ignoring", path)
			return true
		}
	}

	for ignoreFile := range sb.IgnoreFiles {
		// fmt.Println("Checking", path, "against", ignoreFile)
		if strings.HasPrefix(path, ignoreFile) {
			return true
		}
	}
	return false
}

func (sb *SaaSBuilder) genFile(c fileGenConfig) error {
	// Determine the output file name
	fileName := filepath.Base(strings.TrimSuffix(c.templateFile, ".tpl"))

	filePath := filepath.Join(sb.Dir, c.subdir, fileName)

	// check to see if this has been renamed
	actualName := sb.destFile(c.subdir, fileName)
	if newName, exists := sb.RenameFiles[actualName]; exists {
		actualName = newName
	}

	tplFileName := sb.destFile(c.subdir, fileName)
	// fmt.Println("tplFileName:", tplFileName, sb.OverwriteFiles[tplFileName])
	if _, err := os.ReadFile(filepath.Join(sb.Dir, actualName)); err == nil {
		if !sb.OverwriteFiles[tplFileName] {
			// fmt.Println("Skipping file: ", actualName)
			return nil // File exists and overwrite is not allowed
		}
	}

	// snapshot the data map
	// this let's the custom function change it without it being destructive
	savedData := util.CopyMap(sb.Data)

	var content string
	if c.customFunc != nil {
		if err := c.customFunc(sb); err != nil {
			return err
		}
	}

	// update the data map with the custom function changes
	c.data = util.CopyMap(sb.Data)

	// restore the original data map
	sb.Data = savedData

	// fmt.Println("c.templateFile", c.templateFile)

	text, err := fs.ReadFile(templatesFS, c.templateFile)
	if err != nil {
		return fmt.Errorf("template %s not found: %w", c.templateFile, err)
	}

	t := template.Must(
		template.New(
			filepath.Base(c.templateFile),
		).Parse(string(text)),
	)
	buffer := new(bytes.Buffer)
	// fmt.Printf("With data %v\n", c.data)

	err = t.Execute(buffer, c.data)
	if err != nil {
		return err
	}

	content = buffer.String()

	// make sure the folder exists
	if err := os.MkdirAll(filepath.Dir(filePath), 0755); err != nil {
		return err
	}

	code := golang.FormatCode(content)
	if err := os.WriteFile(filePath, []byte(code), 0644); err != nil {
		return err
	}

	renamePath := strings.TrimPrefix(filePath, sb.Dir)
	if renamePath != "" && renamePath[0] == '/' {
		renamePath = renamePath[1:]
	}

	// fmt.Println("Generating file", filePath, renamePath)

	if newName, exists := sb.RenameFiles[renamePath]; exists {
		// rename the file
		newPath := filepath.Join(sb.Dir, newName)
		// fmt.Println("Renaming file", filePath, "to", newPath)

		if err := os.Rename(filePath, newPath); err != nil {
			return err
		}
	}

	// if the file is a .sh file, make it executable
	if strings.HasSuffix(filePath, ".sh") {
		if err := os.Chmod(filePath, 0755); err != nil {
			return err
		}
	}

	return nil
}

func (sb *SaaSBuilder) processFiles() error {
	dbKeywords := []string{"postgres", "mysql", "sqlite", "oracle", "sqlserver"}
	routerKeywords := []string{"echo", "chi", "gin", "native"}

	var files []fileGenConfig

	// Traverse the entire templates directory
	err := fs.WalkDir(templatesFS, "templates", func(path string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return err
		}

		// don't process any db files that are not for the selected db
		for _, keyword := range dbKeywords {
			if strings.Contains(path, "/"+keyword) && sb.DB.String() != keyword {
				return nil
			}
		}

		// don't process any router files that are not for the selected router
		for _, keyword := range routerKeywords {
			if strings.Contains(path, "/"+keyword) && sb.Router.String() != keyword {
				return nil
			}
		}

		if sb.shouldIgnore(path) {
			// fmt.Println("Ignoring path", path)
			return nil // Ignore the file if it matches the ignore criteria
		}

		subdir := strings.TrimPrefix(filepath.Dir(path), "templates")

		// Check and adjust paths for database keyword
		if strings.Contains(path, sb.DB.String()) {
			subdir = strings.Replace(subdir, "/"+sb.DB.String(), "", 1)
		}

		// check and adjust paths for router keyword
		if strings.Contains(path, sb.Router.String()) {
			subdir = strings.Replace(subdir, "/router/"+sb.Router.String(), "/router", 1)
		}

		fileName := filepath.Base(path)

		// Determine if there is a custom logic function for this file
		customFuncName := sb.destFile(subdir, fileName)
		// var custom customFunc
		if _, exists := sb.CustomFuncs[customFuncName]; exists {
			// custom = fn
			return nil
		}

		// Handle dotfiles, custom logic, and regular templates
		files = append(files, fileGenConfig{
			subdir:       subdir,
			templateFile: path,
			// customFunc:   custom,
		})

		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to walk templates directory: %w", err)
	}

	for _, fileConfig := range files {
		if err := sb.genFile(fileConfig); err != nil {
			fmt.Println(err.Error())
		}
	}

	return nil
}

func (sb *SaaSBuilder) destFile(subdir, tplFileName string) string {
	// Determine if there is a custom logic function for this file
	filename := filepath.Join(subdir, tplFileName)
	// remove the leading slash
	if filename[0] == '/' {
		filename = filename[1:]
	}
	// strip the .tpl extension
	return strings.TrimSuffix(filename, ".tpl")

}

func (sb *SaaSBuilder) Execute() error {
	// Process all files including initial, DB-specific, and router-specific files
	if err := sb.processFiles(); err != nil {
		return err
	}

	// Execute all custom functions
	for _, fn := range sb.CustomFuncs {
		if err := fn(sb); err != nil {
			return err
		}
	}

	return nil
}
