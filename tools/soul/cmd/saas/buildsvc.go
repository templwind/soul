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
	var middlewares []string
	var contents []string
	var err error
	if !builder.IsService {
		middlewares = util.GetMiddleware(builder.Spec)

		// read all the files in the middleware directory
		contents, err = readFilesInDirectory(
			path.Join(builder.Dir, builder.ServiceName, types.MiddlewareDir),
		)
		if err != nil {
			fmt.Println("error reading files in middleware directory")
		}

		sort.Strings(middlewares)
	}

	// append the default middleware
	middlewares = append(middlewares, "NoCache")
	included := map[string]bool{}
	for _, item := range middlewares {
		if included[item] {
			continue
		}
		included[item] = true

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
		subdir:       path.Join(builder.ServiceName, types.ContextDir),
		templateFile: "templates/app/internal/svc/servicecontext.go.tpl",
		data:         builder.Data,
	})
}

func genSvcImports(builder *SaaSBuilder, hasMiddlware bool) string {
	i := imports.New()

	if !builder.IsService {
		i.AddNativeImport("context")
	}
	i.AddNativeImport("log")
	i.AddNativeImport("time")

	i.AddProjectImport(path.Join(builder.ModuleName, types.ConfigDir))
	if hasMiddlware && !builder.IsService {
		i.AddProjectImport(path.Join(builder.ModuleName, types.MiddlewareDir))
		i.AddExternalImport("github.com/labstack/echo/v4")
		i.AddProjectImport(path.Join(builder.ServiceName, "internal/session"), "systemSession")
	}

	i.AddProjectImport(path.Join(builder.ServiceName, "internal/awssession"))
	if !builder.IsService {
		i.AddProjectImport(path.Join(builder.ServiceName, "internal/storagemanager"))
	}

	i.AddProjectImport(path.Join(builder.ServiceName, "internal/emailclient/types"), "emailTypes")
	i.AddProjectImport(path.Join(builder.ServiceName, "internal/emailclient/client"))
	i.AddProjectImport(path.Join(builder.ServiceName, "internal/chatgpt"))
	i.AddProjectImport(path.Join(builder.ServiceName, "internal/jobs"))
	i.AddProjectImport(path.Join(builder.ServiceName, "internal/k8sutil"))
	i.AddProjectImport(path.Join(builder.ServiceName, "internal/ratelimiter"))

	i.AddExternalImport("github.com/jmoiron/sqlx")

	if builder.DB == "sqlite" {
		i.AddExternalImport("github.com/mattn/go-sqlite3", "_")
	} else if builder.DB == "postgres" {
		i.AddExternalImport("github.com/lib/pq", "_")
	} else if builder.DB == "mysql" {
		i.AddExternalImport("github.com/go-sql-driver/mysql", "_")
	}

	i.AddExternalImport("github.com/aws/aws-sdk-go/aws/session")
	i.AddExternalImport("github.com/jmoiron/sqlx")
	i.AddExternalImport("github.com/templwind/soul/db")
	i.AddExternalImport("github.com/templwind/soul/pubsub")
	i.AddExternalImport("github.com/templwind/soul/webserver/sse")

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
