package saas

import (
	_ "embed"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/internal/util"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
)

func buildHandlers(builder *SaaSBuilder) error {
	for _, server := range builder.Spec.Servers {
		for _, service := range server.Services {
			for _, handler := range service.Handlers {
				if err := genHandler(builder, server, handler); err != nil {
					return err
				}
			}
		}
	}

	// generate the 404 handler
	return genHandler(builder, spec.Server{
		Annotation: spec.NewAnnotation(map[string]interface{}{
			types.GroupProperty: "notfound",
		}),
	}, spec.Handler{
		Name: "notfound",
		Methods: []spec.Method{
			{
				Method: "GET",
				Route:  "/*",
			},
		},
	})
}

func genHandler(builder *SaaSBuilder, server spec.Server, handler spec.Handler) error {
	handlerName := getHandlerName(handler, nil, true)
	handlerPath := getHandlerFolderPath(server)
	pkgName := strings.ToLower(handlerPath[strings.LastIndex(handlerPath, "/")+1:])
	// logicName := defaultLogicPackage
	if handlerPath != types.HandlerDir {
		handlerName = util.ToPascal(handlerName)
		// logicName = pkgName
	}

	logicName := strings.ToLower(util.ToCamel(handler.Name))

	// get the assetGroup
	assetGroup := server.GetAnnotation("assetGroup")
	if assetGroup == "" {
		assetGroup = "Main"
	} else {
		assetGroup = util.ToPascal(assetGroup)
	}

	// fmt.Println("logicName:", logicName, handler.Name)
	// fmt.Println("handlerPath:", filepath.Join(handlerPath, util.ToKebab(handler.Name)))

	// fmt.Println("server", server)
	// os.Exit(0)

	filename := strings.ToLower(util.ToCamel(handlerName))

	// filename, err := format.FileNamingFormat(cfg.NamingFormat, handlerName)
	// if err != nil {
	// 	return err
	// }

	subDir := getHandlerFolderPath(server)
	handlerFile := path.Join(builder.Dir, subDir, filename+".go")
	if err := os.Remove(handlerFile); err != nil {
		fmt.Println("error removing file", handlerFile, err)
	}

	methods := []types.MethodConfig{}
	for _, method := range handler.Methods {
		// fmt.Println("method:", method.Route)

		if method.IsStatic {
			continue
		}

		hasResp := method.ResponseType != nil && len(method.ResponseType.GetName()) > 0
		hasReq := method.RequestType != nil && len(method.RequestType.GetName()) > 0

		requestType := ""
		if hasReq {
			requestType = util.ToPascal(method.RequestType.GetName())
		}
		responseType := ""
		if hasResp {
			responseType = util.ToPascal(method.ResponseType.GetName())
		}

		handlerName := util.ToPascal(getHandlerName(handler, &method, true))
		callName := util.ToPascal(getHandlerName(handler, &method, false))
		callName = strings.TrimSuffix(callName, "Handler")

		topicsFromClient := []types.Topic{}
		topicsFromServer := []types.Topic{}
		if method.IsSocket {

			for _, topic := range method.SocketNode.Topics {
				var reqType, resType string
				var hasReqType, hasResType bool
				if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
					hasReqType = true
					reqType = util.ToTitle(topic.RequestType.GetName())
				}
				if topic.ResponseType != nil && len(topic.ResponseType.GetName()) > 0 {
					hasResType = true
					resType = util.ToTitle(topic.ResponseType.GetName())
				}

				if !topic.InitiatedByClient {
					topicsFromServer = append(topicsFromServer, types.Topic{
						RawTopic:     strings.TrimSpace(topic.Topic),
						Topic:        "Topic" + util.ToPascal(topic.Topic),
						Name:         topic.GetName(),
						RequestType:  reqType,
						HasReqType:   hasReqType,
						ResponseType: resType,
						HasRespType:  hasResType,
						Call:         util.ToPascal(util.ToTitle(topic.Topic)),
					})
				} else {
					topicsFromClient = append(topicsFromClient, types.Topic{
						RawTopic:     strings.TrimSpace(topic.Topic),
						Topic:        "Topic" + util.ToPascal(topic.Topic),
						Name:         topic.GetName(),
						RequestType:  reqType,
						HasReqType:   hasReqType,
						ResponseType: resType,
						HasRespType:  hasResType,
						Call:         util.ToPascal(util.ToTitle(topic.Topic)),
					})
				}
			}
		}

		// fmt.Println("handlerName:", handlerName)
		methods = append(methods, types.MethodConfig{
			HandlerName:      handlerName,
			RequestType:      requestType,
			ResponseType:     responseType,
			HasResp:          hasResp,
			HasReq:           hasReq,
			HasDoc:           method.Doc != nil,
			HasPage:          method.Page != nil,
			LogicName:        logicName,
			LogicType:        util.ToPascal(getLogicName(handler)),
			Call:             callName, //util.ToPascal(strings.TrimSuffix(handlerName, "Handler")),
			IsSocket:         method.IsSocket,
			TopicsFromClient: topicsFromClient,
			TopicsFromServer: topicsFromServer,
			ReturnsPartial:   method.ReturnsPartial,
			AssetGroup:       assetGroup,
		})
	}

	// b, _ := json.MarshalIndent(methods, "", "  ")
	// fmt.Println("methods", string(b))

	if handler.Name == "notfound" {
		imports := genHandlerImports(server, handler, builder.ModuleName, true)

		builder.Data["PkgName"] = pkgName
		builder.Data["Imports"] = imports
		builder.Data["Methods"] = methods

		builder.WithOverwriteFile(filepath.Join(subDir, "404handler.go"))
		builder.WithRenameFile(filepath.Join(subDir, "404handler.go"), filepath.Join(subDir, "notfoundhandler.go"))
		if err := builder.genFile(fileGenConfig{
			subdir:       subDir,
			templateFile: "templates/internal/handler/404handler.go.tpl",
			data:         builder.Data,
		}); err != nil {
			return err
		}
		return nil
	}

	imports := genHandlerImports(server, handler, builder.ModuleName, false)

	builder.Data["PkgName"] = pkgName
	builder.Data["Imports"] = imports
	builder.Data["Methods"] = methods

	builder.WithOverwriteFile(filepath.Join(subDir, filename+".go"))
	builder.WithRenameFile(filepath.Join(subDir, "handler.go"), filepath.Join(subDir, filename+".go"))
	// builder.WithRenameFile("internal/handler/handler.go", filepath.Join(subDir, filename+".go"))
	return builder.genFile(fileGenConfig{
		subdir:       subDir,
		templateFile: "templates/internal/handler/handler.go.tpl",
		data:         builder.Data,
	})
}

func genHandlerImports(server spec.Server, handler spec.Handler, moduleName string, omitLogic bool) string {
	theme := server.GetAnnotation("theme")
	if len(theme) == 0 {
		theme = "themes/templwind"
	} else {
		theme = "themes/" + theme
	}

	hasTypes := false
	hasTypesFromSocket := false
	requiresEvents := false
	for _, method := range handler.Methods {
		if method.RequestType != nil && len(method.RequestType.GetName()) > 0 {
			hasTypes = true
			break
		}
		if method.IsSocket {
			for _, topic := range method.SocketNode.Topics {
				if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
					hasTypesFromSocket = true
				}
				if topic.ResponseType != nil && len(topic.ResponseType.GetName()) > 0 {
					hasTypesFromSocket = true
				}
				if !topic.InitiatedByClient {
					requiresEvents = true
				}
			}
		}
	}

	hasSocket := false
	hasView := false
	hasReturnsPartial := false
	for _, method := range handler.Methods {
		if method.IsSocket {
			hasSocket = true
			continue
		}

		if method.ReturnsPartial {
			hasReturnsPartial = true
			continue
		}

		if method.Method == "GET" || method.ReturnsPartial {
			hasView = true
		}
	}

	// imports := []string{}
	var iOptFuncs = make([]imports.OptFunc, 0)

	if hasSocket {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "context"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("context"))
		// imports = append(imports, fmt.Sprintf("\"%s\"", "encoding/json"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("encoding/json"))
		// imports = append(imports, fmt.Sprintf("\"%s\"", "log"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("log"))
	} else {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "net/http"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("net/http"))
	}

	if hasView {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "strconv"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("strconv"))

		if omitLogic {
			iOptFuncs = append(iOptFuncs, imports.WithImport("strings"))
		}

		// imports = append(imports, fmt.Sprintf("\"%s\"", "time"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("time"))
	}

	// imports = append(imports, "\n\n")
	iOptFuncs = append(iOptFuncs, imports.WithSpacer())

	if requiresEvents {
		// imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(moduleName, types.EventsDir)))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			"internal/events",
		}...)))
	}

	if !omitLogic {
		// imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(moduleName, getLogicFolderPath(server, handler))))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			getLogicFolderPath(server, handler),
		}...)))
	}
	// imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(moduleName, types.ContextDir)))
	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		moduleName,
		"internal/svc",
	}...)))

	if hasTypes || hasTypesFromSocket {
		// imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(moduleName, types.TypesDir)))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			"internal/types",
		}...)))
	}

	if hasView {
		// imports = append(imports, fmt.Sprintf("\n\nbaseof \"%s\"", pathx.JoinPackages(moduleName, theme, "layouts/baseof")))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"layouts/baseof",
		}...), "baseof"))
		if omitLogic {
			// imports = append(imports, fmt.Sprintf("error4x \"%s\"", pathx.JoinPackages(moduleName, theme, "error4x")))
			iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
				moduleName,
				theme,
				"error4x",
			}...), "error4x"))
		} else {
			// imports = append(imports, fmt.Sprintf("error5x \"%s\"", pathx.JoinPackages(moduleName, theme, "error5x")))
			iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
				moduleName,
				theme,
				"error5x",
			}...), "error5x"))
		}
		// imports = append(imports, fmt.Sprintf("footer \"%s\"", pathx.JoinPackages(moduleName, theme, "partials", "footer")))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"partials",
			"footer",
		}...), "footer"))
		// imports = append(imports, fmt.Sprintf("head \"%s\"", pathx.JoinPackages(moduleName, theme, "partials", "head")))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"partials",
			"head",
		}...), "head"))
		// imports = append(imports, fmt.Sprintf("header \"%s\"", pathx.JoinPackages(moduleName, theme, "partials", "header")))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"partials",
			"header",
		}...), "header"))
		// imports = append(imports, fmt.Sprintf("menu \"%s\"", pathx.JoinPackages(moduleName, theme, "partials", "menu")))
	}

	if hasReturnsPartial {
		// imports = append(imports, fmt.Sprintf("error5x \"%s\"", pathx.JoinPackages(moduleName, theme, "error5x")))
		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"error5x",
		}...), "error5x"))
	}

	// imports = append(imports, "\n\n")
	iOptFuncs = append(iOptFuncs, imports.WithSpacer())

	if hasSocket {
		// imports = append(imports, fmt.Sprintf("gobwasWs \"%s\"", "github.com/gobwas/ws"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/gobwas/ws"))
		// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/gobwas/ws/wsutil"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/gobwas/ws/wsutil"))
	}

	// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/labstack/echo/v4"))
	if hasTypes {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/soul/webserver/httpx"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul/webserver/httpx"))
	}

	if hasView || hasReturnsPartial {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/soul"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul"))
	}

	if hasView {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/soul/htmx"))
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul/htmx"))
	}

	if hasSocket {
		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul/webserver/wsmanager"))
	}

	// return strings.Join(imports, "\n\t")
	return imports.New(iOptFuncs...).String()
}

func getHandlerFolderPath(server spec.Server) string {
	folder := server.GetAnnotation(types.GroupProperty)
	if len(folder) == 0 || folder == "/" {
		return types.HandlerDir
	}

	folder = strings.TrimPrefix(folder, "/")
	folder = strings.TrimSuffix(folder, "/")
	folder = strings.ToLower(util.ToPascal(folder))

	return path.Join(types.HandlerDir, folder)
}
