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
	{{- if .isPubSub }}
	// pubsub routes
	{{.routes}}
	{{- else }}
	////////////////////////////////////////////////////////////
	// {{.prefix}} routes
	////////////////////////////////////////////////////////////
	{{.groupName}} := server.Group(
		"{{.prefix}}",{{if .middlewares}}
		[]echo.MiddlewareFunc{
			{{.middlewares}}
		}...,{{end}}
	)
	{{.groupName}}.Use(middleware.RemoveTrailingSlashWithConfig(middleware.TrailingSlashConfig{
		RedirectCode: http.StatusMovedPermanently,
	}))

	{{.routes}}
	{{- end }}
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
		method             string
		route              string
		staticRouteRewrite string
		handler            string
		doc                map[string]interface{}
		isStatic           bool
		isStaticEmbed      bool
		isSocket           bool
		isPubSub           bool
		topics             []spec.TopicNode
		pubSubTopic        spec.TopicNode
	}
)

func buildRoutes(builder *SaaSBuilder) error {

	var routesAdditionsBuilder strings.Builder
	groups, err := getRoutes(builder.Spec)
	if err != nil {
		return err
	}

	routeFilename := path.Join(builder.Dir, builder.ServiceName, types.HandlerDir, "routes.go")

	// var fsBuilder strings.Builder

	var hasStaticEmbed bool
	var hasTimeout bool
	var jwtEnabled bool
	var isPubSub bool
	var error404Override string
	var ignorePrefixes []string = []string{}
	gt := template.Must(template.New("groupTemplate").Parse(routesAdditionTemplate))
	for _, g := range groups {
		var hasMethods bool
		var routesBuilder strings.Builder
		for _, r := range g.routes {

			if r.isPubSub {
				isPubSub = true
			}
			// fmt.Println("Handler", r.handler)

			if len(r.doc) > 0 {
				routesBuilder.WriteString(fmt.Sprintf("\n%s\n", util.GetDoc(r.doc)))
			}

			if r.isStatic || r.isStaticEmbed {
				// we have to make sure that the static directory exists
				// if it does not exist, we will create it
				staticDirPath := path.Join(builder.Dir, builder.ServiceName, r.route)
				if _, err := os.Stat(staticDirPath); os.IsNotExist(err) {
					fmt.Printf("Static directory does not exist: %s\n", staticDirPath)
					// create the directory
					os.MkdirAll(staticDirPath, 0755)
					// add a .gitkeep file to the directory
					os.Create(path.Join(staticDirPath, ".gitkeep"))
				}

				if g.prefix == "" && r.staticRouteRewrite == "/" {

					var overrideBuilder strings.Builder
					if r.isStaticEmbed {
						hasStaticEmbed = true
						fsEmbeddedName := "embedded" + util.ToPascal(g.name) + util.ToPascal(r.route)

						overrideBuilder.WriteString(fmt.Sprintf(`server.Use(middleware.StaticWithConfig(middleware.StaticConfig{
							Root: "%s",
							Filesystem: http.FS(svcCtx.Config.EmbeddedFS["%s"]),
						}))`,
							strings.TrimPrefix(r.route, "/"),
							fsEmbeddedName,
						))

						builder.EmbeddedFS = append(builder.EmbeddedFS, embeddedFS{
							Path: strings.TrimPrefix(r.route, "/"),
							Name: fsEmbeddedName,
						})
						builder.HasEmbeddedFS = true
					} else {
						overrideBuilder.WriteString(fmt.Sprintf(`server.Group("").Use(middleware.Static("%s"))`,
							strings.TrimPrefix(r.route, "/"),
						))
					}

					error404Override = overrideBuilder.String()
					continue
				}

				// fmt.Printf("r: %+v\n", r)
				if r.staticRouteRewrite == "" {
					r.staticRouteRewrite = r.route
				}

				staticGroupName := util.ToCamel(g.name) + util.ToPascal(r.route) + "StaticGroup"

				routesBuilder.WriteString("\n")
				routesBuilder.WriteString(fmt.Sprintf(`	%s := server.Group("%s")`,
					staticGroupName,
					path.Join(g.prefix, r.staticRouteRewrite),
				))
				routesBuilder.WriteString("\n")

				if r.isStaticEmbed {
					hasStaticEmbed = true
					fsEmbeddedName := "embedded" + util.ToPascal(g.name) + util.ToPascal(r.route)
					builder.EmbeddedFS = append(builder.EmbeddedFS, embeddedFS{
						Path: strings.TrimPrefix(r.route, "/"),
						Name: fsEmbeddedName,
					})
					builder.HasEmbeddedFS = true
					// fsBuilder.Reset()

					// fsName := util.ToCamel(g.name) + util.ToCamel(r.route) + "FS"
					// routesBuilder.WriteString(fmt.Sprintf(`%s, err := fs.Sub(svcCtx.Config.EmbeddedFS["%s"], "%s")`, fsName, fsEmbeddedName, strings.TrimPrefix(r.route, "/")))
					// routesBuilder.WriteString("\n")
					// routesBuilder.WriteString(`	if err != nil {`)
					// routesBuilder.WriteString("\n")
					// routesBuilder.WriteString(fmt.Sprintf(`		server.Logger.Fatal("Failed to create embedded file system for %s:", err)`, r.route))
					// routesBuilder.WriteString("\n")
					// routesBuilder.WriteString(`	}`)
					// routesBuilder.WriteString("\n")
					// routesBuilder.WriteString(fmt.Sprintf(`	%s.GET("%s/*", echo.WrapHandler(http.StripPrefix("%s", http.FileServer(http.FS(%s)))))`,
					// 	util.ToCamel(g.name)+"Group",
					// 	r.staticRouteRewrite,
					// 	r.route,
					// 	fsName,
					// ))
					// routesBuilder.WriteString("\n")
					routesBuilder.WriteString(fmt.Sprintf(
						`	%s.StaticFS("", svcCtx.Config.EmbeddedFS["%s"])`,
						staticGroupName,
						fsEmbeddedName,
						// strings.TrimPrefix(r.staticRouteRewrite, "/"),
					))
				} else {
					routesBuilder.WriteString(fmt.Sprintf(
						`	%s.Static("", "%s")`,
						staticGroupName,
						strings.TrimPrefix(r.route, "/"),
					))
				}
				routesBuilder.WriteString("\n")
				// routesBuilder.WriteString(fmt.Sprintf(`	%s.Use(middleware.AddTrailingSlash())`, staticGroupName))
				// routesBuilder.WriteString("\n")

			} else if isPubSub {
				hasMethods = true
				routesBuilder.WriteString(fmt.Sprintf(
					`%s
	`,
					r.handler,
				))
			} else {
				hasMethods = true
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

		if !hasMethods {
			ignorePrefixes = append(ignorePrefixes, g.name)
			continue
		}

		for i := range g.middlewares {
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
		builder.Data["isPubSub"] = isPubSub
		builder.Data["isService"] = builder.IsService
		builder.Data["error404Override"] = error404Override
		if err := gt.Execute(&routesAdditionsBuilder, builder.Data); err != nil {
			return err
		}

		if len(g.timeout) > 0 {
			hasTimeout = true
		}
	}

	os.Remove(routeFilename)

	builder.Data["hasTimeout"] = hasTimeout
	builder.Data["imports"] = genRouteImports(builder, builder.ModuleName, builder.Spec, hasStaticEmbed, error404Override, ignorePrefixes)
	builder.Data["routesAdditions"] = strings.TrimSpace(routesAdditionsBuilder.String())

	return builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.HandlerDir),
		templateFile: "templates/app/internal/handler/routes.go.tpl",
		data:         builder.Data,
	})
}

func genRouteImports(builder *SaaSBuilder, parentPkg string, site *spec.SiteSpec, hasStaticEmbed bool, error404Override string, ignorePrefixes []string) string {
	i := imports.New()
	hasJwt := false
	for _, server := range site.Servers {
		folder := strings.ToLower(server.GetAnnotation(types.GroupProperty))
		if folder != "" {
			if util.Contains(ignorePrefixes, folder) {
				continue
			}
			i.AddProjectImport(pathx.JoinPackages(parentPkg, types.HandlerDir, folder), toPrefix(folder))
		}
		jwt := server.GetAnnotation("jwt")
		if len(jwt) > 0 {
			hasJwt = true
		}
	}

	folder := "notfound"

	i.AddNativeImport("net/http")

	if hasStaticEmbed {
		// i.AddNativeImport("embed")
		// i.AddNativeImport("io/fs")
		i.AddExternalImport("github.com/labstack/echo/v4/middleware")
	}

	i.AddProjectImport(pathx.JoinPackages(parentPkg, types.ContextDir))
	if !builder.IsService && len(error404Override) == 0 {
		i.AddProjectImport(pathx.JoinPackages(parentPkg, types.HandlerDir, folder))
	}

	i.AddExternalImport("github.com/labstack/echo/v4")
	if hasJwt {
		i.AddExternalImport("github.com/golang-jwt/jwt/v5")
		i.AddExternalImport("github.com/labstack/echo-jwt/v4")

	}

	return i.Build()
}

func getRoutes(site *spec.SiteSpec) ([]group, error) {
	var routes []group

	for _, server := range site.Servers {
		var groupedRoutes group
		folder := strings.ToLower(server.GetAnnotation(types.GroupProperty))
		// fmt.Println("folder", folder)

		// last part of the folder name but it may not include "/"
		// parts := strings.Split(folder, "/")
		// if len(parts) >= 2 {
		// 	groupedRoutes.name = util.ToCamel(parts[len(parts)-2]) + util.ToPascal(parts[len(parts)-1])
		// } else {
		// 	groupedRoutes.name = parts[len(parts)-1]
		// }
		groupedRoutes.name = util.ToCamel(folder)

		for _, s := range server.Services {
			for _, r := range s.Handlers {
				// handlerName := getHandlerName(r, nil)
				// handlerName = handlerName + "(svcCtx)"

				for _, m := range r.Methods {
					// fmt.Println("m", m)
					// if m.RequestType != nil {
					var handlerName string
					if !m.IsPubSub {
						handlerName = util.ToTitle(getHandlerName(r, &m))
					} else {
						baseName, err := getHandlerBaseName(r)
						if err != nil {
							panic(err)
						}
						handlerName = util.ToPascal(baseName) + util.ToPascal(m.PubSubNode.Route)
					}

					if len(folder) > 0 {
						handlerName = toPrefix(folder) + "." + util.ToPascal(handlerName)
					}

					// fmt.Println("handlerName", handlerName)

					mRoute := strings.TrimSuffix(m.Route, "/")

					// fmt.Println("mRoute", mRoute)

					if m.IsPubSub {
						// "go " +
						handlerName = "go " + handlerName + fmt.Sprintf(`(svcCtx, "%s", "%s")`, mRoute, r.Name)
					} else {
						handlerName = handlerName + fmt.Sprintf(`(svcCtx, "%s")`, mRoute)
					}

					routeObj := route{
						method:             mapping[strings.ToLower(m.Method)],
						route:              mRoute,
						staticRouteRewrite: m.StaticRouteRewrite,
						handler:            handlerName,
						doc:                m.DocAnnotation.Properties,
						isStatic:           m.IsStatic,
						isStaticEmbed:      m.IsStaticEmbed,
						isSocket:           m.IsSocket,
						isPubSub:           m.IsPubSub,
					}

					if m.IsSocket && m.SocketNode != nil {
						routeObj.topics = m.SocketNode.Topics
					}

					if m.IsPubSub && m.PubSubNode != nil {
						routeObj.pubSubTopic = m.PubSubNode.Topic
					}
					// // fmt.Println("handlerName", handlerName)
					// fmt.Println("routeObj.isPubSub", routeObj.isPubSub)

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
