package saas

import (
	"bytes"
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
	"github.com/zeromicro/go-zero/tools/goctl/pkg/golang"
)

//go:embed templates/** templates/**/.github/** templates/**/postgres/.github/**
var templatesFS embed.FS

type SaaSBuilder struct {
	Dir            string
	ModuleName     string
	ServiceName    string
	DB             types.DBType
	Router         types.RouterType
	Spec           *spec.SiteSpec
	Data           map[string]any
	CustomFuncs    map[string]customFunc
	RenameFiles    map[string]string
	IgnoreFiles    map[string]bool
	IgnorePaths    map[string]bool
	OverwriteFiles map[string]bool
	IsService      bool
}

type customFunc func(saasBuilder *SaaSBuilder) error
type optFunc[T any] func(*T)

func NewSaaSBuilder(opts ...optFunc[SaaSBuilder]) *SaaSBuilder {
	sb := defaultProps()

	for _, opt := range opts {
		opt(sb)
	}

	if sb.Dir == "" {
		panic("dir is required")
	}
	if sb.ModuleName == "" {
		panic("module name is required")
	}
	if sb.ServiceName == "" {
		panic("service name is required")
	}
	if sb.Spec == nil {
		panic("site spec is required")
	}
	return sb
}

func defaultProps() *SaaSBuilder {
	return &SaaSBuilder{
		IgnoreFiles:    map[string]bool{"handler.go.tpl": true},
		IgnorePaths:    map[string]bool{"templates/internal/handler/": true},
		OverwriteFiles: make(map[string]bool),
		Data:           make(map[string]any),
		CustomFuncs:    make(map[string]customFunc),
		RenameFiles:    make(map[string]string),
		IsService:      false,
	}
}

// dir, moduleName, serviceName string, db types.DBType, router types.RouterType, siteSpec *spec.SiteSpec
func WithDir(dir string) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.Dir = dir
	}
}

func WithModuleName(moduleName string) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.ModuleName = moduleName
	}
}

func WithServiceName(serviceName string) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.ServiceName = serviceName
	}
}

func WithDB(db types.DBType) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.DB = db
	}
}

func WithRouter(router types.RouterType) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.Router = router
	}
}

func WithSiteSpec(siteSpec *spec.SiteSpec) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.Spec = siteSpec
	}
}

func WithIsService(isService bool) optFunc[SaaSBuilder] {
	return func(sb *SaaSBuilder) {
		sb.IsService = isService
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
		fmt.Println("Checking", path, "against", ignorePath, strings.HasPrefix(path, ignorePath))
		if strings.HasPrefix(path, ignorePath) {
			// fmt.Println("Ignoring", path)
			return true
		}
	}

	for ignoreFile := range sb.IgnoreFiles {
		// fmt.Println("Ignore Check", path, "against", ignoreFile, strings.HasPrefix(path, ignoreFile))
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

	// fmt.Println("Generating file", filePath)

	// Check if the file needs to be renamed
	actualName := sb.destFile(c.subdir, fileName)
	if newName, exists := sb.RenameFiles[actualName]; exists {
		actualName = newName
	} else {
		// Check for any rename pattern that affects the path
		for origName, renamedName := range sb.RenameFiles {
			if strings.HasPrefix(actualName, origName) {
				actualName = strings.Replace(actualName, origName, renamedName, 1)
				break
			}
		}
	}

	tplFileName := sb.destFile(c.subdir, fileName)

	// Ensure the destination directory exists
	destDir := filepath.Dir(actualName)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	// Read the file to check if it exists
	if _, err := os.ReadFile(filepath.Join(sb.Dir, actualName)); err == nil {
		if !sb.OverwriteFiles[tplFileName] {
			// Skip the file if it exists and overwrite is not allowed
			return nil
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

	// Define the pattern for migration files
	migrationPattern := regexp.MustCompile(`^[0-9]+_.*\.sql$`)

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

			// Check the destination directory for the db keyword
			dest := strings.TrimPrefix(filepath.Dir(path), "templates")
			if strings.Contains(dest, keyword) {
				destinationDir := filepath.Join(sb.Dir, dest)

				// strip the keyword from the destination directory
				destinationDir = strings.Replace(destinationDir, "/"+keyword, "", 1)

				// Check if we're in the migrations directory
				if strings.Contains(strings.ToLower(destinationDir), "migrations") {
					// Get the base name of the current file
					baseName := filepath.Base(path)

					// Check if the current file matches the migration pattern
					if migrationPattern.MatchString(baseName) {

						files, _ := os.ReadDir(destinationDir)

						// Check if there's already a file with the same numeric prefix
						currentPrefix := strings.SplitN(baseName, "_", 2)[0]
						for _, file := range files {
							// fmt.Println("Looking at file", file.Name(), currentPrefix)

							if migrationPattern.MatchString(file.Name()) {
								existingPrefix := strings.SplitN(file.Name(), "_", 2)[0]
								if currentPrefix == existingPrefix {
									return nil
								}
							}
						}
					}
				}
			}
		}

		// don't process any router files that are not for the selected router
		for _, keyword := range routerKeywords {
			if strings.Contains(path, "/"+keyword) && sb.Router.String() != keyword {
				return nil
			}
		}

		if sb.shouldIgnore(path) {
			return nil // Ignore the file if it matches the ignore criteria
		}

		subdir := strings.TrimPrefix(filepath.Dir(path), "templates")
		// Replace the "app/" prefix with the ServiceName
		if strings.HasPrefix(subdir, "/app") {
			subdir = strings.Replace(subdir, "/app", "/"+sb.ServiceName, 1)
		}

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
		// fmt.Println("customFuncName::", customFuncName)
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
		// fmt.Println("Generating file", fileConfig.subdir)

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
