package saas

import (
	_ "embed"
	"fmt"
	"path"
	"path/filepath"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/util"
)

func buildMiddleware(builder *SaaSBuilder) error {
	if builder.IsService {
		return nil
	}

	middlewares := util.GetMiddleware(builder.Spec)

	// add the default middlewares
	if !builder.IsService {
		middlewares = append(middlewares, []string{
			"AccountGuard",
			"AuthGuard",
			"UserGuard",
			"NoCache",
		}...)
	} else {
		middlewares = append(middlewares, []string{
			"NoCache",
		}...)
	}

	for _, item := range middlewares {
		noCache := false
		if strings.EqualFold(item, "nocache") {
			noCache = true
		}

		middlewareFilename := strings.TrimSuffix(strings.ToLower(item), "middleware")
		// fmt.Println("generating middleware:", middlewareFilename)

		// fmt.Println("generating middleware:", filepath.Join(
		// 	"app",
		// 	types.MiddlewareDir,
		// 	middlewareFilename+".go",
		// ))

		builder.WithRenameFile(
			filepath.Join(
				builder.ServiceName,
				types.MiddlewareDir,
				"template.go"),
			filepath.Join(
				builder.ServiceName,
				types.MiddlewareDir,
				middlewareFilename+".go",
			))

		builder.Data["name"] = util.ToTitle(strings.TrimSuffix(item, "Middleware") + "Middleware")
		builder.Data["imports"] = imports.New(
			imports.WithImport("github.com/labstack/echo/v4"),
		).String()
		builder.Data["isNoCache"] = noCache

		err := builder.genFile(fileGenConfig{
			subdir: path.Join(builder.ServiceName, types.MiddlewareDir),
			templateFile: filepath.Join(
				"templates",
				"app",
				types.MiddlewareDir,
				"template.go.tpl",
			),
			data: builder.Data,
		})
		if err != nil {
			fmt.Println("gen middleware failed:", err)
		}
	}

	return nil
}
