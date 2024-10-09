package echo

import (
	_ "embed"
	"fmt"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

//go:embed templates/main.tpl
var mainTemplate string

func genMain(dir, rootPkg string, cfg *config.Config, site *spec.SiteSpec) error {
	name := strings.ToLower(site.Name)
	filename, err := format.FileNamingFormat(cfg.NamingFormat, name)
	if err != nil {
		return err
	}

	configName := filename
	if strings.HasSuffix(filename, "-api") {
		filename = strings.ReplaceAll(filename, "-api", "")
	}

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          "",
		filename:        filename + ".go",
		templateName:    "mainTemplate",
		category:        category,
		templateFile:    mainTemplateFile,
		builtinTemplate: mainTemplate,
		data: map[string]string{
			"importPackages": genMainImports(rootPkg),
			"serviceName":    configName,
		},
	})
}

func genMainImports(parentPkg string) string {
	var imports []string
	imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.ConfigDir)))
	imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.HandlerDir)))
	imports = append(imports, fmt.Sprintf("\"%s\"\n", pathx.JoinPackages(parentPkg, types.ContextDir)))
	imports = append(imports, fmt.Sprintf("_ \"%s\"", "github.com/joho/godotenv/autoload"))
	imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4/middleware"))
	imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/soul/conf"))
	imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/soul/webserver"))
	return strings.Join(imports, "\n\t")
}
