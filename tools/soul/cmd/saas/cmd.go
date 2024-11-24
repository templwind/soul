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
	var (
		varApiFile               string
		varDir                   string
		varDB                    string
		varRouter                string
		varCGO                   string
		varExternalDockerNetwork string
		varIgnoreDBMigrations    bool
		varIsService             bool
		varIgnorePaths           []string
	)

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

			var ignoreDBMigrations bool
			if varIgnoreDBMigrations {
				ignoreDBMigrations = true
			} else {
				ignoreDBMigrations = false
			}

			var isService bool
			if varIsService {
				isService = true
			} else {
				isService = false
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

			opts := doGenProjectOptions{
				siteFile:              siteFile,
				dir:                   dir,
				db:                    db,
				router:                router,
				cgoEnabled:            cgoEnabled,
				ignoreDBMigrations:    ignoreDBMigrations,
				isService:             isService,
				externalDockerNetwork: externalDockerNetwork,
				ignorePaths:           ignorePaths,
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
	cmd.Flags().StringVarP(&varDB, "db", "b", "pg", "Database to use")
	cmd.Flags().StringVarP(&varRouter, "router", "r", "echo", "Router to use")
	cmd.Flags().StringVarP(&varCGO, "cgo", "c", "", "CGO_ENABLED")
	cmd.Flags().BoolVarP(&varIgnoreDBMigrations, "migrations", "m", false, "Ignore generating the database migrations and folders")
	cmd.Flags().BoolVarP(&varIsService, "service", "s", false, "Generate as a service")
	cmd.Flags().StringVarP(&varExternalDockerNetwork, "network", "n", "", "External docker network")
	cmd.Flags().StringSliceVarP(&varIgnorePaths, "ignore", "i", []string{}, "Ignore paths")
	return cmd
}

type doGenProjectOptions struct {
	siteFile              string
	dir                   string
	db                    types.DBType
	router                types.RouterType
	cgoEnabled            bool
	ignoreDBMigrations    bool
	isService             bool
	externalDockerNetwork string
	ignorePaths           map[string]bool
}

func doGenProject(opts doGenProjectOptions) error {

	// siteFile, dir string, db types.DBType, router types.RouterType, cgoEnabled, ignoreDBMigrations, isService bool) error {
	p, err := parser.NewParser(opts.siteFile)
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

	logx.Must(pathx.MkdirIfNotExist(opts.dir))
	// basePkg, err := golang.GetParentPackage(dir)
	// if err != nil {
	// 	fmt.Println(color.Red.Sprintf("get parent package failed: %s", err.Error()))
	// 	return err
	// }

	moduleName := util.ToPkgName(siteSpec.Name)
	// fmt.Println(color.Green.Sprintf("Generating project in %s", dir, moduleName))
	// os.Exit(0)

	serviceName := strings.ToLower(siteSpec.Name)

	// first things first, download the modules into ram
	// builder := NewSaaSBuilder(dir, moduleName, serviceName, db, router, siteSpec)
	builder := NewSaaSBuilder(
		WithDir(opts.dir),
		WithModuleName(moduleName),
		WithServiceName(serviceName),
		WithDB(opts.db),
		WithRouter(opts.router),
		WithSiteSpec(siteSpec),
		WithIsService(opts.isService),
		WithExternalDockerNetwork(opts.externalDockerNetwork),
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
			"isService":             opts.isService,
			"externalDockerNetwork": opts.externalDockerNetwork,
		},
	)

	// set the files to rename
	builder.WithRenameFiles(map[string]string{
		// "app/air.toml":     "app/.air.toml",
		// "env":              ".env",
		// "app/gitignore":    "app/.gitignore",
		// "app/dockerignore": "app/.dockerignore",
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
	if !opts.isService {
		builder.WithCustomFunc(serviceName+"/internal/config/menus.go", buildMenus)
	} else {
		builder.WithIgnoreFile("app/internal/config/menus.go")
	}

	// internal/handler/*.go
	builder.WithCustomFunc(serviceName+"/internal/handler/handler.go", buildHandlers)

	// internal/handler/routes.go
	builder.WithCustomFunc(serviceName+"/internal/handler/routes.go", buildRoutes)

	// internal/embeds.go
	builder.WithCustomFunc(serviceName+"/embeds.go", buildEmbeds)

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

	if !opts.isService {
		// ignore the src/api files (interfaces.ts and functions.ts)
		builder.WithIgnoreFile("app/src/api/endpoints.ts")
		builder.WithIgnoreFile("app/src/api/models.ts")
		builder.WithCustomFunc(serviceName+"/src/api/models.ts", buildApi)

		// check to see if the models directory exists and has files in it
		modelsPath := path.Join(opts.dir, serviceName, types.ModelsDir)
		if entries, err := os.ReadDir(modelsPath); err == nil && len(entries) > 0 {
			builder.WithIgnorePath("app/internal/models")
		}

		for ignore := range opts.ignorePaths {
			builder.WithIgnorePath(path.Join("app", ignore))
		}
	} else {
		// builder.WithIgnorePath("app/internal/middleware")
		builder.WithIgnoreFiles(
			"app/internal/middleware/accountguard.go",
			"app/internal/middleware/authguard.go",
			"app/internal/middleware/chooseaccountguard.go",
			"app/internal/middleware/middleware.go",
			"app/internal/middleware/template.go",
			"app/internal/middleware/userguard.go",
		)

		// ignore temporal
		builder.WithIgnorePath("temporal")
		builder.WithIgnorePath("app/internal/workflow")

		// ignore types
		builder.WithIgnoreFiles(
			"app/internal/types/temportaltopics.go",
		)

		// ignore the rest of the internal folders
		builder.WithIgnorePath("app/internal/emailclient")
		builder.WithIgnorePath("app/internal/tokens")
		builder.WithIgnorePath("app/internal/security")
		builder.WithIgnorePath("app/internal/session")
		builder.WithIgnorePath("app/internal/settings")
		builder.WithIgnorePath("app/internal/storagemanager")
		builder.WithIgnorePath("app/internal/ui")
		builder.WithIgnorePath("app/themes")
		builder.WithIgnorePath("app/src")
		builder.WithIgnoreFile("app/package.json")
		builder.WithIgnoreFile("app/postcss.config.js")
		builder.WithIgnoreFile("app/tailwind.config.js")
		builder.WithIgnoreFile("app/tsconfig.json")
		builder.WithIgnoreFile("app/tsconfig.node.json")
		builder.WithIgnoreFile("app/tsconfig.svelte.json")
		builder.WithIgnoreFile("app/vite.config.ts")

		builder.WithIgnoreFiles(
			"db/" + opts.db.String() + "/migrations/3_email.sql",
		)

		// ignore the models we don't need
		builder.WithIgnoreFiles(
			"app/internal/models/"+opts.db.String()+"/account.ext.go",
			"app/internal/models/"+opts.db.String()+"/account.go",
			"app/internal/models/"+opts.db.String()+"/account.xo.go",
			"app/internal/models/"+opts.db.String()+"/attachment.ext.go",
			"app/internal/models/"+opts.db.String()+"/attachment.xo.go",
			"app/internal/models/"+opts.db.String()+"/auditlog.ext.go",
			"app/internal/models/"+opts.db.String()+"/auditlog.xo.go",
			"app/internal/models/"+opts.db.String()+"/bucket.ext.go",
			"app/internal/models/"+opts.db.String()+"/bucket.xo.go",
			"app/internal/models/"+opts.db.String()+"/comment.ext.go",
			"app/internal/models/"+opts.db.String()+"/comment.xo.go",
			// "app/internal/models/"+opts.db.String()+"/db.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailcampaign.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailcampaign.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailclick.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailclick.xo.go",
			"app/internal/models/"+opts.db.String()+"/emaillink.ext.go",
			"app/internal/models/"+opts.db.String()+"/emaillink.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailmetric.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailmetric.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailopen.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailopen.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailrecipient.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailrecipient.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailsend.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailsend.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailsender.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailsender.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailstatus.go",
			"app/internal/models/"+opts.db.String()+"/emailstatushistory.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailstatushistory.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailtemplate.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailtemplate.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailtype.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailtype.xo.go",
			"app/internal/models/"+opts.db.String()+"/emailunsubscribe.ext.go",
			"app/internal/models/"+opts.db.String()+"/emailunsubscribe.xo.go",
			"app/internal/models/"+opts.db.String()+"/invoice.ext.go",
			"app/internal/models/"+opts.db.String()+"/invoice.xo.go",
			"app/internal/models/"+opts.db.String()+"/notification.ext.go",
			"app/internal/models/"+opts.db.String()+"/notification.xo.go",
			"app/internal/models/"+opts.db.String()+"/oauthstate.ext.go",
			"app/internal/models/"+opts.db.String()+"/oauthstate.xo.go",
			"app/internal/models/"+opts.db.String()+"/paymentattempt.ext.go",
			"app/internal/models/"+opts.db.String()+"/paymentattempt.xo.go",
			"app/internal/models/"+opts.db.String()+"/paymentmethod.ext.go",
			"app/internal/models/"+opts.db.String()+"/paymentmethod.xo.go",
			"app/internal/models/"+opts.db.String()+"/permission.ext.go",
			"app/internal/models/"+opts.db.String()+"/permission.xo.go",
			"app/internal/models/"+opts.db.String()+"/post.ext.go",
			"app/internal/models/"+opts.db.String()+"/post.xo.go",
			"app/internal/models/"+opts.db.String()+"/product.ext.go",
			"app/internal/models/"+opts.db.String()+"/product.xo.go",
			"app/internal/models/"+opts.db.String()+"/publicid.go",
			"app/internal/models/"+opts.db.String()+"/review.ext.go",
			"app/internal/models/"+opts.db.String()+"/review.xo.go",
			"app/internal/models/"+opts.db.String()+"/role.ext.go",
			"app/internal/models/"+opts.db.String()+"/role.xo.go",
			"app/internal/models/"+opts.db.String()+"/rolepermission.ext.go",
			"app/internal/models/"+opts.db.String()+"/rolepermission.xo.go",
			"app/internal/models/"+opts.db.String()+"/setting.ext.go",
			"app/internal/models/"+opts.db.String()+"/setting.xo.go",
			"app/internal/models/"+opts.db.String()+"/subscription.ext.go",
			"app/internal/models/"+opts.db.String()+"/subscription.xo.go",
			"app/internal/models/"+opts.db.String()+"/tag.ext.go",
			"app/internal/models/"+opts.db.String()+"/tag.xo.go",
			"app/internal/models/"+opts.db.String()+"/transactions.ext.go",
			"app/internal/models/"+opts.db.String()+"/user.ext.go",
			"app/internal/models/"+opts.db.String()+"/user.go",
			"app/internal/models/"+opts.db.String()+"/user.xo.go",
			"app/internal/models/"+opts.db.String()+"/useraccount.ext.go",
			"app/internal/models/"+opts.db.String()+"/useraccount.xo.go",
			"app/internal/models/"+opts.db.String()+"/userrole.ext.go",
			"app/internal/models/"+opts.db.String()+"/userrole.xo.go",
			"app/internal/models/"+opts.db.String()+"/usertype.ext.go",
			"app/internal/models/"+opts.db.String()+"/usertype.go",
			"app/internal/models/"+opts.db.String()+"/usertype.xo.go",
			// "app/internal/models/"+opts.db.String()+"/xid.go",
		)
	}

	builder.Execute()

	if !opts.isService {
		// make sure the assets and static directories are created
		_ = os.MkdirAll(path.Join(opts.dir, builder.ServiceName, "assets"), os.ModePerm)
		_ = os.MkdirAll(path.Join(opts.dir, builder.ServiceName, "static"), os.ModePerm)
	}

	if err := backupAndSweep(opts.siteFile); err != nil {
		return err
	}

	// if err := format.ApiFormatByPath(siteFile, false); err != nil {
	// 	return err
	// }

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
			ignore: opts.isService,
			args:   []string{"npm", "i", "-g", "pnpm@latest", "--force"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(opts.dir, serviceName),
		},
		{
			ignore: opts.isService,
			args:   []string{"pnpm", "i", "--force"},
			condition: func() bool {
				return true // Always run this command
			},
			dir: path.Join(opts.dir, serviceName),
		},
		{
			ignore: opts.isService,
			args:   []string{"git", "init"},
			condition: func() bool {
				// Only run this command if .git directory does not exist
				if _, err := os.Stat(path.Join(opts.dir, serviceName, ".git")); os.IsNotExist(err) {
					return true
				}
				return false
			},
			dir: path.Join(opts.dir, serviceName),
		},
		{
			ignore: opts.isService,
			args:   []string{"git", "init"},
			condition: func() bool {
				// Only run this command if .git directory does not exist
				if _, err := os.Stat(path.Join(opts.dir, "db", ".git")); os.IsNotExist(err) {
					return true
				}

				return false
			},
			dir: path.Join(opts.dir, "db"),
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
