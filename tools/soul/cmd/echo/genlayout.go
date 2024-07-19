package echo

import (
	_ "embed"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/templwind/templwind/tools/soul/internal/types"
	"github.com/templwind/templwind/tools/soul/internal/util"
	"github.com/templwind/templwind/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

//go:embed templates/layout.tpl
var layoutTemplate string

//go:embed templates/layout.templ.tpl
var layoutTemplTemplate string

var layoutMap = map[string]struct{}{}

func genLayout(dir, rootPkg string, cfg *config.Config, site *spec.SiteSpec) error {
	layoutMap = make(map[string]struct{})
	for _, server := range site.Servers {
		layoutName := server.GetAnnotation("template")
		if len(layoutName) != 0 {
			layoutMap[layoutName] = struct{}{}
		}

		for _, service := range server.Services {
			for _, handler := range service.Handlers {
				for _, method := range handler.Methods {
					if method.Page != nil {
						if key, ok := method.Page.Annotation.Properties["template"]; ok {
							if layoutName, ok := key.(string); ok {
								layoutMap[layoutName] = struct{}{}
							}
						}
					}
				}
			}
		}
	}

	for layoutName := range layoutMap {
		err := genLayoutByServer(dir, rootPkg, cfg, layoutName)
		if err != nil {
			return err
		}
	}

	// os.Exit(0)
	return nil
}

func genLayoutByServer(dir, rootPkg string, cfg *config.Config, layoutName string) error {

	// fmt.Println("layoutName:", layoutName)

	subDir := filepath.Join(types.LayoutsDir, strings.ToLower(util.ToCamel(layoutName+"Layout")))
	pkgName := subDir[strings.LastIndex(subDir, "/")+1:]

	if subDir != types.LayoutsDir {
		layoutName = pkgName
	}

	// fmt.Println("layoutName:", subDir, layoutName)

	// filename, err := format.FileNamingFormat(cfg.NamingFormat, layoutName)
	// if err != nil {
	// 	return err
	// }

	templImports := genTemplLayoutImports(rootPkg)
	imports := genLayoutImports(rootPkg)

	if err := genFile(fileGenConfig{
		dir:             dir,
		subdir:          subDir,
		filename:        "layout.templ",
		templateName:    "layoutTemplTemplate",
		category:        category,
		templateFile:    layoutTemplTemplateFile,
		builtinTemplate: layoutTemplTemplate,
		data: map[string]any{
			"PkgName": pkgName,
			"Imports": templImports,
		},
	}); err != nil {
		return err
	}

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          subDir,
		filename:        "props.go",
		templateName:    "layoutTemplate",
		category:        category,
		templateFile:    layoutTemplateFile,
		builtinTemplate: layoutTemplate,
		data: map[string]any{
			"PkgName": pkgName,
			"Imports": imports,
			"tplName": "layout",
		},
	})
}

func genLayoutImports(parentPkg string) string {
	imports := []string{
		fmt.Sprintf("\"%s\"\n", "net/http"),
		fmt.Sprintf("\"%s\"\n", pathx.JoinPackages(parentPkg, types.ConfigDir)),
		fmt.Sprintf("\"%s\"", "github.com/a-h/templ"),
		fmt.Sprintf("\"%s\"", "github.com/templwind/templwind"),
	}

	return strings.Join(imports, "\n\t")
}

func genTemplLayoutImports(parentPkg string) string {
	imports := []string{
		fmt.Sprintf("\"%s\"\n", pathx.JoinPackages(parentPkg, types.ContextDir)),
		fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4"),
	}

	return strings.Join(imports, "\n\t")
}
