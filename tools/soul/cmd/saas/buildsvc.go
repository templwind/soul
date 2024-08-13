package saas

import (
	_ "embed"
	"fmt"
	"path"
	"sort"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/util"
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

	imports := genSvcImports(builder, len(middlewares) > 0)

	builder.Data["imports"] = imports
	builder.Data["config"] = "config.Config"
	builder.Data["middleware"] = middlewareStr
	builder.Data["middlewareAssignment"] = middlewareAssignment

	return builder.genFile(fileGenConfig{
		subdir:       path.Join("app", types.ContextDir),
		templateFile: "templates/app/internal/svc/servicecontext.go.tpl",
		data:         builder.Data,
	})
}

func genSvcImports(builder *SaaSBuilder, hasMiddlware bool) string {
	i := imports.New()
	i.AddNativeImport(path.Join(builder.ModuleName, types.ConfigDir))
	if hasMiddlware {
		i.AddNativeImport(path.Join(builder.ModuleName, types.MiddlewareDir))
		i.AddExternalImport("github.com/labstack/echo/v4")
	}

	i.AddExternalImport("github.com/jmoiron/sqlx")

	if builder.DB == "sqlite" {
		i.AddExternalImport("github.com/mattn/go-sqlite3", "_")
	} else if builder.DB == "postgres" {
		i.AddExternalImport("github.com/lib/pq", "_")
	} else if builder.DB == "mysql" {
		i.AddExternalImport("github.com/go-sql-driver/mysql", "_")
	}

	i.AddExternalImport("github.com/jmoiron/sqlx")
	i.AddExternalImport("github.com/templwind/soul/db")

	return i.Build()

	// imports = append(imports, "\n\n")
	// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/jmoiron/sqlx"))

	// if hasMiddlware {
	// 	imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4"))
	// }

	// imports = append(imports, fmt.Sprintf("_ \"%s\"", "github.com/mattn/go-sqlite3"))
	// imports = append(imports, fmt.Sprintf("\"%s/db\"", "github.com/templwind/soul"))

	// return strings.Join(imports, "\n\t")
}
