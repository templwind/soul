package site

import (
	_ "embed"
	"fmt"
	"strings"

	"github.com/templwind/templwind/tools/soul/internal/types"
	"github.com/templwind/templwind/tools/soul/internal/util"
	"github.com/templwind/templwind/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
	"github.com/zeromicro/go-zero/tools/goctl/vars"
)

const contextFilename = "service_context"

//go:embed svc.tpl
var contextTemplate string

func genServiceContext(dir, rootPkg string, cfg *config.Config, site *spec.SiteSpec) error {
	filename, err := format.FileNamingFormat(cfg.NamingFormat, contextFilename)
	if err != nil {
		return err
	}

	var middlewareStr string
	var middlewareAssignment string
	middlewares := util.GetMiddleware(site)

	for _, item := range middlewares {
		middlewareStr += fmt.Sprintf("%s rest.Middleware\n", item)
		name := strings.TrimSuffix(item, "Middleware") + "Middleware"
		middlewareAssignment += fmt.Sprintf("%s: %s,\n", item,
			fmt.Sprintf("middleware.New%s().%s", strings.Title(name), "Handle"))
	}

	configImport := "\"" + pathx.JoinPackages(rootPkg, types.ConfigDir) + "\""
	if len(middlewareStr) > 0 {
		configImport += "\n\t\"" + pathx.JoinPackages(rootPkg, types.MiddlewareDir) + "\""
		configImport += fmt.Sprintf("\n\t\"%s/rest\"", vars.ProjectOpenSourceURL)
	}

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          types.ContextDir,
		filename:        filename + ".go",
		templateName:    "contextTemplate",
		category:        category,
		templateFile:    contextTemplateFile,
		builtinTemplate: contextTemplate,
		data: map[string]string{
			"configImport":         configImport,
			"config":               "config.Config",
			"middleware":           middlewareStr,
			"middlewareAssignment": middlewareAssignment,
		},
	})
}
