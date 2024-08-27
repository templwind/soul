package saas

import (
	"fmt"
	"os"
	"path"
	"strings"
	"text/template"
	"time"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

const (
	routesAdditionTemplate = `
	{{.groupName}} := server.Group(
		"{{.prefix}}",{{if .middlewares}}
		[]echo.MiddlewareFunc{
			{{.middlewares}}
		}...,{{end}}
	)

	{{.routes}}
`
	timeoutThreshold = time.Millisecond
)

var mapping = map[string]string{
	"static":  "STATIC",
	"delete":  "DELETE",
	"get":     "GET",
	"head":    "HEAD",
	"post":    "POST",
	"put":     "PUT",
	"patch":   "PATCH",
	"connect": "CONNECT",
	"options": "OPTIONS",
	"trace":   "TRACE",
}

type (
	group struct {
		name             string
		routes           []route
		jwtEnabled       bool
		signatureEnabled bool
		authName         string
		timeout          string
		middlewares      []string
		prefix           string
		jwtTrans         string
		maxBytes         string
	}
	route struct {
		method   string
		route    string
		handler  string
		doc      map[string]interface{}
		isStatic bool
		isSocket bool
		topics   []spec.TopicNode
	}
)

func buildRoutes(builder *SaaSBuilder) error {
	var routesAdditionsBuilder strings.Builder
	groups, err := getRoutes(builder.Spec)
	if err != nil {
		return err
	}

	routeFilename := path.Join(builder.Dir, "app", types.HandlerDir, "routes.go")

	var hasTimeout bool
	var jwtEnabled bool
	gt := template.Must(template.New("groupTemplate").Parse(routesAdditionTemplate))
	for _, g := range groups {
		var routesBuilder strings.Builder
		for _, r := range g.routes {
			// fmt.Println("Handler", r.handler)

			if len(r.doc) > 0 {
				routesBuilder.WriteString(fmt.Sprintf("\n%s\n", util.GetDoc(r.doc)))
			}
			if r.isStatic {
				routesBuilder.WriteString(fmt.Sprintf(
					`%s.Static("%s", "%s")
	`,
					util.ToCamel(g.name)+"Group",
					r.route,
					"public"+r.route,
				))
			} else {
				routesBuilder.WriteString(fmt.Sprintf(
					`%s.%s("%s", %s)
	`,
					util.ToCamel(g.name)+"Group",
					mapping[strings.ToLower(r.method)],
					r.route,
					r.handler,
				))
			}
		}

		for i, _ := range g.middlewares {
			g.middlewares[i] = "svcCtx." + util.ToTitle(g.middlewares[i]) + ","
		}

		if g.jwtEnabled {
			jwtEnabled = true
			jwtMiddleware := `echojwt.WithConfig(echojwt.Config{
				NewClaimsFunc: func(c echo.Context) jwt.Claims { return new(jwtCustomClaims) },
				SigningKey: []byte(svcCtx.Config.` + g.authName + `.AccessSecret),
				TokenLookup:  "cookie:auth",
				ErrorHandler: func(c echo.Context, err error) error {
					c.Redirect(302, "/auth/login")
					return nil
				},
			}),`

			// Prepend jwt middleware
			g.middlewares = append([]string{jwtMiddleware}, g.middlewares...)
		}

		builder.Data["jwtEnabled"] = jwtEnabled
		builder.Data["groupName"] = util.ToCamel(g.name) + "Group"
		builder.Data["middlewares"] = strings.Join(g.middlewares, "\n\t\t\t")
		builder.Data["routes"] = routesBuilder.String()
		builder.Data["prefix"] = g.prefix

		if err := gt.Execute(&routesAdditionsBuilder, builder.Data); err != nil {
			return err
		}

		if len(g.timeout) > 0 {
			hasTimeout = true
		}
	}

	os.Remove(routeFilename)

	builder.Data["hasTimeout"] = hasTimeout
	builder.Data["imports"] = genRouteImports(builder.ModuleName, builder.Spec)
	builder.Data["routesAdditions"] = strings.TrimSpace(routesAdditionsBuilder.String())

	return builder.genFile(fileGenConfig{
		subdir:       path.Join("app", types.HandlerDir),
		templateFile: "templates/app/internal/handler/routes.go.tpl",
		data:         builder.Data,
	})
}

func genRouteImports(parentPkg string, site *spec.SiteSpec) string {
	i := imports.New()
	hasJwt := false
	for _, server := range site.Servers {
		folder := strings.ToLower(server.GetAnnotation(types.GroupProperty))
		i.AddProjectImport(pathx.JoinPackages(parentPkg, types.HandlerDir, folder), toPrefix(folder))
		jwt := server.GetAnnotation("jwt")
		if len(jwt) > 0 {
			hasJwt = true
		}
	}

	folder := "notfound"

	i.AddProjectImport(pathx.JoinPackages(parentPkg, types.ContextDir))
	i.AddProjectImport(pathx.JoinPackages(parentPkg, types.HandlerDir, folder))

	i.AddExternalImport("github.com/labstack/echo/v4")
	if hasJwt {
		i.AddExternalImport("github.com/golang-jwt/jwt/v5")
		i.AddExternalImport("github.com/labstack/echo-jwt/v4")

	}

	return i.Build()

	// importSet.AddStr(fmt.Sprintf("\"%s\"",
	// 	pathx.JoinPackages(pathx.JoinPackages(parentPkg, types.HandlerDir, folder))))

	// imports := importSet.KeysStr()
	// sort.Strings(imports)
	// projectSection := strings.Join(imports, "\n\t")
	// depSection := []string{`"github.com/golang-jwt/jwt/v5"`}
	// if hasJwt {
	// 	depSection = append(depSection, `"github.com/labstack/echo-jwt/v4"`)
	// }
	// depSection = append(depSection, `"github.com/labstack/echo/v4"`)
	// return fmt.Sprintf("%s\n\n\t%s", projectSection, strings.Join(depSection, "\n\t"))
}

func getRoutes(site *spec.SiteSpec) ([]group, error) {
	var routes []group

	for _, server := range site.Servers {
		var groupedRoutes group
		folder := strings.ToLower(server.GetAnnotation(types.GroupProperty))
		// fmt.Println("folder", folder)

		// last part of the folder name but it may not include "/"
		groupedRoutes.name = folder[strings.LastIndex(folder, "/")+1:]
		for _, s := range server.Services {
			for _, r := range s.Handlers {
				// handlerName := getHandlerName(r, nil)
				// handlerName = handlerName + "(svcCtx)"

				for _, m := range r.Methods {
					// fmt.Println("m", m)
					// if m.RequestType != nil {
					handlerName := util.ToTitle(getHandlerName(r, &m))
					if len(folder) > 0 {
						handlerName = toPrefix(folder) + "." + util.ToPascal(handlerName)
					}

					// fmt.Println("handlerName", handlerName)

					mRoute := strings.TrimSuffix(m.Route, "/")

					// fmt.Println("mRoute", mRoute)

					handlerName = handlerName + fmt.Sprintf(`(svcCtx, "%s")`, mRoute)

					routeObj := route{
						method:   mapping[strings.ToLower(m.Method)],
						route:    mRoute,
						handler:  handlerName,
						doc:      m.DocAnnotation.Properties,
						isStatic: m.IsStatic,
						isSocket: m.IsSocket,
					}

					if m.IsSocket && m.SocketNode != nil {
						routeObj.topics = m.SocketNode.Topics
					}
					// fmt.Println("handlerName", handlerName)

					groupedRoutes.routes = append(groupedRoutes.routes, routeObj)
					// }
				}
			}
		}

		groupedRoutes.timeout = server.GetAnnotation("timeout")
		groupedRoutes.maxBytes = server.GetAnnotation("maxBytes")

		jwt := server.GetAnnotation("jwt")
		if len(jwt) > 0 {
			groupedRoutes.authName = jwt
			groupedRoutes.jwtEnabled = true
		}
		jwtTrans := server.GetAnnotation(types.JwtTransKey)
		if len(jwtTrans) > 0 {
			groupedRoutes.jwtTrans = jwtTrans
		}

		signature := server.GetAnnotation("signature")
		if signature == "true" {
			groupedRoutes.signatureEnabled = true
		}
		middleware := server.GetAnnotation("middleware")
		if len(middleware) > 0 {
			groupedRoutes.middlewares = append(groupedRoutes.middlewares, strings.Split(middleware, ",")...)
		}
		prefix := server.GetAnnotation("prefix")
		prefix = strings.ReplaceAll(prefix, `"`, "")
		prefix = strings.TrimSpace(prefix)
		if len(prefix) > 0 {
			prefix = path.Join("/", prefix)
			groupedRoutes.prefix = prefix
		}
		routes = append(routes, groupedRoutes)
	}

	return routes, nil
}

func toPrefix(folder string) string {
	replacer := strings.NewReplacer("/", "", "-", "")
	return replacer.Replace(folder)
	// return strings.ReplaceAll(folder, "/", "")
}
