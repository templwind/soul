package saas

import (
	_ "embed"
	"fmt"
	"path"
	"sort"
	"strings"

	"github.com/templwind/soul/tools/soulctl/internal/types"
	"github.com/templwind/soul/tools/soulctl/internal/util"

	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

func buildServiceContext(builder *SaaSBuilder) error {
	var middlewareStr string
	var middlewareAssignment string
	middlewares := util.GetMiddleware(builder.Spec)

	// read all the files in the middleware directory
	contents, err := readFilesInDirectory(
		path.Join(builder.Dir, types.MiddlewareDir),
	)
	if err != nil {
		fmt.Println("error reading files in middleware directory")
	}

	sort.Strings(middlewares)

	for _, item := range middlewares {
		// read from the tpl file to determine
		// if we have a cfg *config.Config and/or db models.DB

		middlewareStr += fmt.Sprintf("%s echo.MiddlewareFunc\n", item)
		name := strings.TrimSuffix(item, "Middleware") + "Middleware"

		reqString := []string{}
		// see if it exists in the contents
		for _, content := range contents {
			if strings.Contains(content, name) {
				// do we have cfg *config.Config and/or db models.DB
				if strings.Contains(content, "cfg *config.Config") {
					reqString = append(reqString, "c")
				}
				if strings.Contains(content, "db models.DB") {
					reqString = append(reqString, "sqlxDB")
				}
			}
		}

		middlewareAssignment += fmt.Sprintf("%s: %s,\n", item,
			fmt.Sprintf("middleware.New%s(%s).%s", strings.Title(name), strings.Join(reqString, ", "), "Handle"))
	}

	imports := genSvcImports(builder.ModuleName, len(middlewares) > 0)

	builder.Data["imports"] = imports
	builder.Data["config"] = "config.Config"
	builder.Data["middleware"] = middlewareStr
	builder.Data["middlewareAssignment"] = middlewareAssignment

	return builder.genFile(fileGenConfig{
		subdir:       types.ContextDir,
		templateFile: "templates/internal/svc/servicecontext.go.tpl",
		data:         builder.Data,
	})
}

func genSvcImports(rootPkg string, hasMiddlware bool) string {
	imports := []string{}
	imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(rootPkg, types.ConfigDir)))
	if hasMiddlware {
		imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(rootPkg, types.MiddlewareDir)))
	}

	imports = append(imports, "\n\n")
	imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/jmoiron/sqlx"))

	if hasMiddlware {
		imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4"))
	}

	imports = append(imports, fmt.Sprintf("_ \"%s\"", "github.com/mattn/go-sqlite3"))
	imports = append(imports, fmt.Sprintf("\"%s/db\"", "github.com/templwind/soul"))

	return strings.Join(imports, "\n\t")
}
