package new

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/parser"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	"github.com/gookit/color"
	"github.com/spf13/cobra"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

const tmpFile = "%s-%d"

var (
	tmpDir = path.Join(os.TempDir(), "soul")
)

// ClientConfig stores the type and destination path for a generated API client
type ClientConfig struct {
	Type string // "admin" or "default"
	Path string // Absolute path for the client files
}

func Cmd() *cobra.Command {
	var (
		varApiFile               string
		varDir                   string
		varDB                    string
		varRouter                string
		varCGO                   string
		varExternalDockerNetwork string
		varIgnoreDBMigrations    bool
		varIgnorePaths           []string
		varClients               []string // New flag for client configurations
	)

	var cmd = &cobra.Command{
		Use:   "new",
		Short: "Generate a new project",
		Long:  `Generate a new project with the given name`,
		Run: func(cmd *cobra.Command, args []string) {
			siteFile, err := filepath.Abs(varApiFile)
			if err != nil {
				panic(err)
			}

			// get the absolute path of the directory
			dir, err := filepath.Abs(varDir)
			if err != nil {
				panic(err)
			}

			var db types.DBType
			switch varDB {
			case "postgres":
				fallthrough
			case "pg":
				db = types.Postgres
			case "mysql":
				db = types.MySql
			case "sqlite":
				db = types.Sqlite
			default:
				db = types.Postgres
			}

			var router types.RouterType
			switch varRouter {
			case "echo":
				router = types.Echo
			case "chi":
				router = types.Chi
			case "gin":
				router = types.Gin
			case "native":
				router = types.Native
			default:
				router = types.Echo
			}

			var cgoEnabled bool
			if varCGO != "" {
				cgoEnabled = true
			} else {
				cgoEnabled = false
			}

			var ignoreDBMigrations bool
			if varIgnoreDBMigrations {
				ignoreDBMigrations = true
			} else {
				ignoreDBMigrations = false
			}

			var externalDockerNetwork string
			if varExternalDockerNetwork != "" {
				externalDockerNetwork = varExternalDockerNetwork
			} else {
				externalDockerNetwork = "" // soul
			}

			var ignorePaths map[string]bool
			if len(varIgnorePaths) > 0 {
				ignorePaths = make(map[string]bool)
				for _, path := range varIgnorePaths {
					ignorePaths[path] = true
				}
			}

			// Parse and validate client configurations
			clients := []ClientConfig{}
			for _, clientArg := range varClients {
				parts := strings.SplitN(clientArg, ":", 2)
				if len(parts) != 2 {
					fmt.Println(color.Red.Sprintf("Invalid client format: %s. Use 'type:path' (e.g., 'admin:/path/to/admin/api')", clientArg))
					os.Exit(1)
				}
				clientType := strings.ToLower(parts[0])
				clientPath := parts[1]

				if clientType != "admin" && clientType != "default" {
					fmt.Println(color.Red.Sprintf("Invalid client type '%s' in '%s'. Must be 'admin' or 'default'", clientType, clientArg))
					os.Exit(1)
				}

				absClientPath, err := filepath.Abs(clientPath)
				if err != nil {
					fmt.Println(color.Red.Sprintf("Invalid client path '%s': %v", clientPath, err))
					os.Exit(1)
				}

				clients = append(clients, ClientConfig{
					Type: clientType,
					Path: absClientPath,
				})
			}

			opts := doGenProjectOptions{
				siteFile:              siteFile,
				dir:                   dir,
				db:                    db,
				router:                router,
				cgoEnabled:            cgoEnabled,
				ignoreDBMigrations:    ignoreDBMigrations,
				externalDockerNetwork: externalDockerNetwork,
				ignorePaths:           ignorePaths,
				clients:               clients, // Pass parsed client configs
			}

			if err := doGenProject(opts); err != nil {
				fmt.Println(color.Red.Sprintf("failed to generate project: %s", err.Error()))
			}
		},
	}

	cmd.Flags().StringVarP(&varApiFile, "api", "a", "", "Path to the api file")
	cmd.MarkFlagRequired("api")
	cmd.Flags().StringVarP(&varDir, "dir", "d", "", "Directory to create the site in")
	cmd.MarkFlagRequired("dir")
	cmd.Flags().StringVarP(&varDB, "db", "b", "pg", "Database to use (pg, mysql, sqlite)")
	cmd.Flags().StringVarP(&varRouter, "router", "r", "echo", "Router to use (echo, chi, gin, native)")
	cmd.Flags().StringVarP(&varCGO, "cgo", "c", "", "Set CGO_ENABLED=1 (pass any non-empty string)")
	cmd.Flags().BoolVarP(&varIgnoreDBMigrations, "migrations", "m", false, "Ignore generating the database migrations and folders")
	cmd.Flags().StringVarP(&varExternalDockerNetwork, "network", "n", "", "External docker network name for docker-compose")
	cmd.Flags().StringSliceVarP(&varIgnorePaths, "ignore", "i", []string{}, "Ignore paths relative to the app directory (e.g., 'internal/models')")
	// Add the new client flag
	cmd.Flags().StringSliceVarP(&varClients, "client", "l", []string{}, "Define API client generation (repeatable). Format: 'type:path'. Type is 'admin' or 'default'. Path is the output directory (e.g., --client admin:../admin/src/lib/api)")

	return cmd
}

type doGenProjectOptions struct {
	siteFile              string
	dir                   string
	db                    types.DBType
	router                types.RouterType
	cgoEnabled            bool
	ignoreDBMigrations    bool
	externalDockerNetwork string
	ignorePaths           map[string]bool
	clients               []ClientConfig // Store client configurations
}

func doGenProject(opts doGenProjectOptions) error {
	p, err := parser.NewParser(opts.siteFile)
	if err != nil {
		fmt.Println(color.Red.Sprintf("parse site file failed: %s", err.Error()))
		return err
	}

	parsedAST := p.Parse()
	siteSpec := spec.BuildSiteSpec(parsedAST)

	_, err = spec.SetServiceName(siteSpec)
	if err != nil {
		fmt.Println(color.Red.Sprintf("get service name failed: %s", err.Error()))
		return err
	}

	if err := siteSpec.Validate(); err != nil {
		fmt.Println(color.Red.Sprintf("validate site spec failed: %s", err.Error()))
		return err
	}

	logx.Must(pathx.MkdirIfNotExist(opts.dir))

	moduleName := util.ToPkgName(siteSpec.Name)

	serviceName := strings.ToLower(siteSpec.Name)

	// first things first, download the modules into ram
	builder := NewSaaSBuilder(
		WithDir(opts.dir),
		WithModuleName(moduleName),
		WithServiceName(serviceName),
		WithDB(opts.db),
		WithRouter(opts.router),
		WithSiteSpec(siteSpec),
		WithExternalDockerNetwork(opts.externalDockerNetwork),
		WithClientConfigs(opts.clients), // Pass client configs to builder
	)

	// set the default data for the builder
	builder.WithData(
		map[string]any{
			"serviceName":           serviceName,
			"dsnName":               strings.ToLower(siteSpec.Name),
			"filename":              util.ToCamel(siteSpec.Name),
			"hasWorkflow":           false,
			"cgoEnabled":            opts.cgoEnabled,
			"dbType":                opts.db,
			"ignoreDBMigrations":    opts.ignoreDBMigrations,
			"externalDockerNetwork": opts.externalDockerNetwork,
		},
	)

	// set the files to rename
	builder.WithRenameFiles(map[string]string{
		serviceName + "/air.toml":        serviceName + "/.air.toml",
		serviceName + "/prettyrc":        serviceName + "/.prettierrc",
		serviceName + "/prettierignore":  serviceName + "/.prettierignore",
		serviceName + "/gitignore":       serviceName + "/.gitignore",
		serviceName + "/dockerignore":    serviceName + "/.dockerignore",
		serviceName + "/assets/keep":     serviceName + "/assets/.keep",
		serviceName + "/static/keep":     serviceName + "/static/.keep",
		serviceName + "/main.go":         serviceName + "/" + strings.ToLower(siteSpec.Name) + ".go",
		serviceName + "/etc/config.yaml": serviceName + "/etc/" + moduleName + ".yaml",
	})

	if opts.ignoreDBMigrations {
		builder.WithIgnorePath("db")
	}

	// ignore the whole internal/logic directory
	builder.WithIgnorePath("app/internal/logic")
	builder.WithIgnorePath("app/internal/handler")
	builder.WithIgnoreFile("app/internal/types/loginvalidation.go")
	builder.WithIgnoreFile("app/internal/types/registervalidation.go")
	builder.WithIgnoreFile("app/embeds.go")

	// etc/etc.yaml
	builder.WithCustomFunc(serviceName+"/etc/config.yaml", buildEtc)

	// internal/config/config.go
	builder.WithIgnorePath("app/internal/config")
	builder.WithCustomFunc(serviceName+"/internal/config/config.go", buildConfig)
	builder.WithIgnoreFile("app/internal/config/menus.go")

	// internal/handler/*.go
	builder.WithCustomFunc(serviceName+"/internal/handler/handler.go", buildHandlers)

	// internal/handler/routes.go
	builder.WithCustomFunc(serviceName+"/internal/handler/routes.go", buildRoutes)

	// internal/logic/*.go
	builder.WithCustomFunc(serviceName+"/internal/logic/logic.go", buildLogic)

	// internal/middleware/*.go
	builder.WithIgnoreFile("app/internal/middleware/template.go")
	builder.WithCustomFunc(serviceName+"/internal/middleware/template.go", buildMiddleware)

	// internal/svc/servicecontext.go
	builder.WithCustomFunc(serviceName+"/internal/svc/servicecontext.go", buildServiceContext)

	// internal/types/types.go
	builder.WithCustomFunc(serviceName+"/internal/types/types.go", buildTypes)

	// main.go
	builder.WithCustomFunc(serviceName+"/main.go", buildMain)

	// *** REMOVED API related IgnoreFile and CustomFunc calls here ***
	// buildApi will now handle generation based on ClientConfigs passed to the builder

	// check to see if the models directory exists and has files in it
	modelsPath := path.Join(opts.dir, serviceName, types.ModelsDir)
	if entries, err := os.ReadDir(modelsPath); err == nil && len(entries) > 0 {
		builder.WithIgnorePath("app/internal/models")
	}

	for ignore := range opts.ignorePaths {
		builder.WithIgnorePath(path.Join("app", ignore))
	}

	// *** Add the buildApi custom function call back ***
	// This will trigger the API client generation logic in buildapi.go
	// We pass a dummy filename as it's not strictly tied to one output file anymore.
	builder.WithCustomFunc("api_generation_trigger", buildApi)

	builder.Execute()

	if err := backupAndSweep(opts.siteFile); err != nil {
		return err
	}

	// Save the current working directory
	originalDir, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("get current directory failed: %w", err)
	}

	type cmdStruct struct {
		ignore      bool
		args        []string
		condition   func() bool
		asGoRoutine bool
		delay       time.Duration
		dir         string // New field to specify the directory for each command
	}

	commands := []cmdStruct{
		{
			ignore: false,
			args:   []string{"go", "mod", "init", moduleName},
			condition: func() bool {
				// Only run this command if go.mod does not exist
				if _, err := os.Stat(path.Join(opts.dir, serviceName, "go.mod")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(opts.dir, serviceName),
		},
		{
			ignore: false,
			args:   []string{"go", "mod", "tidy"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(opts.dir, serviceName),
		},
		{
			ignore: false,
			args:   []string{"git", "init"},
			condition: func() bool {
				// Only run this command if .git directory does not exist
				if _, err := os.Stat(path.Join(opts.dir, ".git")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(opts.dir, serviceName),
		},
	}

	for _, command := range commands {
		if command.condition() {

			if command.ignore {
				continue
			}

			// Change to the command's directory
			if err := os.Chdir(command.dir); err != nil {
				return fmt.Errorf("change directory to %s failed: %w", command.dir, err)
			}

			cmd := exec.Command(command.args[0], command.args[1:]...)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			run := func(cmd *exec.Cmd, command cmdStruct) {
				if command.delay > 0 {
					time.Sleep(command.delay)
				}
				if err := cmd.Run(); err != nil {
					fmt.Fprintf(os.Stderr, "failed to run '%s': %v\n", strings.Join(command.args, " "), err)
					os.Exit(1)
				}
			}

			if command.asGoRoutine {
				// go run(cmd, command)
			} else {
				run(cmd, command)
			}

			// Change back to the original directory
			if err := os.Chdir(originalDir); err != nil {
				return fmt.Errorf("change directory back to %s failed: %w", originalDir, err)
			}
		}
	}

	fmt.Println(color.Green.Render("Done."))
	return nil
}

func runCmd(cmd *exec.Cmd) error {
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func openBrowser(url string) error {
	var cmd string
	var args []string

	switch os := runtime.GOOS; os {
	case "windows":
		cmd = "rundll32"
		args = []string{"url.dll,FileProtocolHandler", url}
	case "darwin":
		cmd = "open"
		args = []string{url}
	default: // "linux", "freebsd", "openbsd", "netbsd"
		cmd = "xdg-open"
		args = []string{url}
	}

	return exec.Command(cmd, args...).Start()
}

func downloadModule(module spec.Module) error {
	return nil
}

func backupAndSweep(siteFile string) error {
	var err error
	var wg sync.WaitGroup

	wg.Add(2)
	_ = os.MkdirAll(tmpDir, os.ModePerm)

	go func() {
		defer wg.Done()
		_, fileName := filepath.Split(siteFile)
		_, e := util.Copy(siteFile, fmt.Sprintf(path.Join(tmpDir, tmpFile), fileName, time.Now().Unix()))
		if e != nil {
			err = e
		}
	}()
	go func() {
		defer wg.Done()
		if e := sweep(); e != nil {
			err = e
		}
	}()

	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return err
	}
}

func sweep() error {
	keepTime := time.Now().AddDate(0, 0, -7)
	return filepath.Walk(tmpDir, func(fpath string, info os.FileInfo, err error) error {
		if info.IsDir() {
			return nil
		}

		pos := strings.LastIndexByte(info.Name(), '-')
		if pos > 0 {
			timestamp := info.Name()[pos+1:]
			seconds, err := strconv.ParseInt(timestamp, 10, 64)
			if err != nil {
				// print error and ignore
				fmt.Println(color.Red.Sprintf("sweep ignored file: %s", fpath))
				return nil
			}

			tm := time.Unix(seconds, 0)
			if tm.Before(keepTime) {
				if err := os.RemoveAll(fpath); err != nil {
					fmt.Println(color.Red.Sprintf("failed to remove file: %s", fpath))
					return err
				}
			}
		}

		return nil
	})
}
