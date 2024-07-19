package site

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/templwind/templwind/tools/soul/internal/util"
	"github.com/templwind/templwind/tools/soul/pkg/site/parser"
	"github.com/templwind/templwind/tools/soul/pkg/site/spec"

	"github.com/gookit/color"
	"github.com/spf13/cobra"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/pkg/golang"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

const tmpFile = "%s-%d"

var (
	tmpDir = path.Join(os.TempDir(), "soul")
)

func Cmd() *cobra.Command {
	var varApiFile string
	var varDir string

	var cmd = &cobra.Command{
		Use:   "site",
		Short: "Generate a new site",
		Long:  `Generate a new site with the given name`,
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

			doGenProject(siteFile, dir)
		},
	}

	cmd.Flags().StringVarP(&varApiFile, "api", "a", "", "Path to the api file")
	cmd.MarkFlagRequired("api")
	cmd.Flags().StringVarP(&varDir, "dir", "d", "", "Directory to create the site in")
	cmd.MarkFlagRequired("dir")

	return cmd
}

func doGenProject(siteFile, dir string) error {
	p, err := parser.NewParser(siteFile)
	if err != nil {
		fmt.Println(color.Red.Sprintf("parse site file failed: %s", err.Error()))
		return err
	}

	parsedAST := p.Parse()
	siteSpec := spec.BuildSiteSpec(parsedAST)

	// spec.PrintSpec(*siteSpec)

	_, err = spec.SetServiceName(siteSpec)
	if err != nil {
		fmt.Println(color.Red.Sprintf("get service name failed: %s", err.Error()))
		return err
	}

	if err := siteSpec.Validate(); err != nil {
		fmt.Println(color.Red.Sprintf("validate site spec failed: %s", err.Error()))
		return err
	}

	cfg, err := config.NewConfig("")
	if err != nil {
		fmt.Println(color.Red.Sprintf("load config failed: %s", err.Error()))
		return err
	}

	logx.Must(pathx.MkdirIfNotExist(dir))
	rootPkg, err := golang.GetParentPackage(dir)
	if err != nil {
		fmt.Println(color.Red.Sprintf("get parent package failed: %s", err.Error()))
		return err
	}

	logx.Must(genEtc(dir, cfg, siteSpec))
	logx.Must(genConfig(dir, cfg, siteSpec))
	logx.Must(genMain(dir, rootPkg, cfg, siteSpec))
	logx.Must(genServiceContext(dir, rootPkg, cfg, siteSpec))
	logx.Must(genTypes(dir, cfg, siteSpec))
	logx.Must(genRoutes(dir, rootPkg, cfg, siteSpec))
	logx.Must(genHandlers(dir, rootPkg, cfg, siteSpec))
	logx.Must(genLogic(dir, rootPkg, cfg, siteSpec))
	logx.Must(genMiddleware(dir, cfg, siteSpec))

	if err := backupAndSweep(siteFile); err != nil {
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

	// Change directory to the target directory before running 'go mod tidy'
	if err := os.Chdir(dir); err != nil {
		return fmt.Errorf("change directory to %s failed: %w", dir, err)
	}

	// Run go mod tidy
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run 'go mod tidy': %w", err)
	}

	// Change back to the original directory
	if err := os.Chdir(originalDir); err != nil {
		return fmt.Errorf("change directory back to %s failed: %w", originalDir, err)
	}

	fmt.Println(color.Green.Render("Done."))
	return nil
}

func backupAndSweep(siteFile string) error {
	var err error
	var wg sync.WaitGroup

	wg.Add(2)
	_ = os.MkdirAll(tmpDir, os.ModePerm)

	go func() {
		_, fileName := filepath.Split(siteFile)
		_, e := util.Copy(siteFile, fmt.Sprintf(path.Join(tmpDir, tmpFile), fileName, time.Now().Unix()))
		if e != nil {
			err = e
		}
		wg.Done()
	}()
	go func() {
		if e := sweep(); e != nil {
			err = e
		}
		wg.Done()
	}()
	wg.Wait()

	return err
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
