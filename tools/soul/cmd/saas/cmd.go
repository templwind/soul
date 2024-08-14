package saas

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

func Cmd() *cobra.Command {
	var varApiFile string
	var varDir string
	var varDB string
	var varRouter string
	var varCGO string

	var cmd = &cobra.Command{
		Use:   "saas",
		Short: "Generate a new saas site",
		Long:  `Generate a new saas site with the given name`,
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

			if err := doGenProject(siteFile, dir, db, router, cgoEnabled); err != nil {
				fmt.Println(color.Red.Sprintf("failed to generate project: %s", err.Error()))
			}
		},
	}

	cmd.Flags().StringVarP(&varApiFile, "api", "a", "", "Path to the api file")
	cmd.MarkFlagRequired("api")
	cmd.Flags().StringVarP(&varDir, "dir", "d", "", "Directory to create the site in")
	cmd.MarkFlagRequired("dir")
	cmd.Flags().StringVarP(&varDB, "db", "b", "pg", "Database to use")
	cmd.Flags().StringVarP(&varRouter, "cgo", "c", "", "CGO_ENABLED")

	return cmd
}

func doGenProject(siteFile, dir string, db types.DBType, router types.RouterType, cgoEnabled bool) error {
	p, err := parser.NewParser(siteFile)
	if err != nil {
		fmt.Println(color.Red.Sprintf("parse site file failed: %s", err.Error()))
		return err
	}

	parsedAST := p.Parse()
	siteSpec := spec.BuildSiteSpec(parsedAST)

	// b, _ := json.MarshalIndent(siteSpec, "", "  ")
	// fmt.Println("siteSpec", string(b))
	// // spec.PrintSpec(*siteSpec)
	// parser.PrintAST(parsedAST)

	// os.Exit(0)

	_, err = spec.SetServiceName(siteSpec)
	if err != nil {
		fmt.Println(color.Red.Sprintf("get service name failed: %s", err.Error()))
		return err
	}

	if err := siteSpec.Validate(); err != nil {
		fmt.Println(color.Red.Sprintf("validate site spec failed: %s", err.Error()))
		return err
	}

	// cfg, err := config.NewConfig("")
	// if err != nil {
	// 	fmt.Println(color.Red.Sprintf("load config failed: %s", err.Error()))
	// 	return err
	// }

	logx.Must(pathx.MkdirIfNotExist(dir))
	// basePkg, err := golang.GetParentPackage(dir)
	// if err != nil {
	// 	fmt.Println(color.Red.Sprintf("get parent package failed: %s", err.Error()))
	// 	return err
	// }

	moduleName := util.ToPkgName(siteSpec.Name)
	// fmt.Println(color.Green.Sprintf("Generating project in %s", dir, moduleName))
	// os.Exit(0)

	// first things first, download the modules into ram
	builder := NewSaaSBuilder(dir, moduleName, db, router, siteSpec)

	// set the default data for the builder
	builder.WithData(
		map[string]any{
			"serviceName": strings.ToLower(siteSpec.Name),
			"dsnName":     strings.ToLower(siteSpec.Name),
			"filename":    util.ToCamel(siteSpec.Name),
			"hasWorkflow": false,
			"cgoEnabled":  cgoEnabled,
			"dbType":      db,
		},
	)

	// set the files to rename
	builder.WithRenameFiles(map[string]string{
		// "app/air.toml":     "app/.air.toml",
		// "env":              ".env",
		// "app/gitignore":    "app/.gitignore",
		// "app/dockerignore": "app/.dockerignore",
		"app/main.go": "app/" + strings.ToLower(siteSpec.Name) + ".go",
	})

	// ignore the whole internal/logic directory
	builder.WithIgnorePath("app/internal/logic")
	builder.WithIgnorePath("app/internal/handler")
	builder.WithIgnoreFile("app/internal/types/loginvalidation.go")
	builder.WithIgnoreFile("app/internal/types/registervalidation.go")

	// main.go
	builder.WithCustomFunc("app/main.go", buildMain)

	// etc/etc.yaml
	builder.WithCustomFunc("app/etc/config.yaml", buildEtc)
	builder.WithRenameFile("app/etc/config.yaml", "app/etc/"+moduleName+".yaml")

	// internal/config/config.go
	builder.WithIgnorePath("app/internal/config")
	builder.WithCustomFunc("app/internal/config/config.go", buildConfig)
	builder.WithCustomFunc("app/internal/config/menus.go", buildMenus)

	// internal/handler/*.go
	builder.WithCustomFunc("app/internal/handler/handler.go", buildHandlers)

	// internal/handler/routes.go
	builder.WithCustomFunc("app/internal/handler/routes.go", buildRoutes)

	// internal/logic/*.go
	builder.WithCustomFunc("app/internal/logic/logic.go", buildLogic)

	// internal/middleware/*.go
	builder.WithIgnoreFile("app/internal/middleware/template.go")
	builder.WithCustomFunc("app/internal/middleware/template.go", buildMiddleware)

	// internal/svc/servicecontext.go
	builder.WithCustomFunc("app/internal/svc/servicecontext.go", buildServiceContext)

	// internal/types/types.go
	builder.WithCustomFunc("app/internal/types/types.go", buildTypes)

	// ignore the src/api files (interfaces.ts and functions.ts)
	builder.WithIgnoreFile("app/src/api/endpoints.ts")
	builder.WithIgnoreFile("app/src/api/models.ts")
	builder.WithCustomFunc("app/src/api/models.ts", buildApi)

	builder.Execute()

	// make sure the assets and static directories are created
	_ = os.MkdirAll(path.Join(dir, "app/assets"), os.ModePerm)
	_ = os.MkdirAll(path.Join(dir, "app/static"), os.ModePerm)

	if err := backupAndSweep(siteFile); err != nil {
		return err
	}

	// if err := format.ApiFormatByPath(siteFile, false); err != nil {
	// 	return err
	// }

	// Save the current working directory
	// Save the current working directory
	originalDir, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("get current directory failed: %w", err)
	}

	type cmdStruct struct {
		args        []string
		condition   func() bool
		asGoRoutine bool
		delay       time.Duration
		dir         string // New field to specify the directory for each command
	}

	commands := []cmdStruct{
		{
			args: []string{"go", "mod", "init", moduleName},
			condition: func() bool {
				// Only run this command if go.mod does not exist
				if _, err := os.Stat(path.Join(dir, "app", "go.mod")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(dir, "app"),
		},
		{
			args: []string{"go", "mod", "tidy"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(dir, "app"),
		},
		{
			args: []string{"npm", "i", "-g", "pnpm@latest", "--force"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(dir, "app"),
		},
		{
			args: []string{"pnpm", "i", "--force"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(dir, "app"),
		},
		{
			args: []string{"git", "init"},
			condition: func() bool {
				// Only run this command if .git directory does not exist
				if _, err := os.Stat(path.Join(dir, "app", ".git")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(dir, "app"),
		},
		{
			args: []string{"git", "init"},
			condition: func() bool {
				// Only run this command if .git directory does not exist
				if _, err := os.Stat(path.Join(dir, "db", ".git")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(dir, "db"),
		},
	}

	for _, command := range commands {
		if command.condition() {
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

	// Open the browser to the correct URL and port
	// port := 8888
	// url := fmt.Sprintf("http://localhost:%d", port)
	// if err := openBrowser(url); err != nil {
	// 	fmt.Fprintf(os.Stderr, "failed to open browser: %v\n", err)
	// }

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
