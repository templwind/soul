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
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
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
	// layoutPath := getLogicLayoutPath(server)

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

	filename := strings.ToLower(util.ToCamel(handlerName))

	// has socket
	var NewRequiresSocket bool
	for _, method := range handler.Methods {
		if method.IsSocket {
			NewRequiresSocket = true
			break
		}
	}

	subDir := getHandlerFolderPath(server)
	handlerFile := path.Join(builder.Dir, "app", subDir, filename+".go")
	if _, err := os.Stat(handlerFile); err == nil {
		if err := os.Remove(handlerFile); err != nil {
			fmt.Println("error removing file", handlerFile, err)
		}
	}

	methods := []types.MethodConfig{}
	uniqueMethods := []string{}
	for _, method := range handler.Methods {
		handlerName := util.ToPascal(getHandlerName(handler, &method))

		// fmt.Println("handlerName", handlerName)

		if util.Contains(uniqueMethods, handlerName) {
			continue
		}
		uniqueMethods = append(uniqueMethods, handlerName)

		// fmt.Println("method:", method.Route)

		// if method.IsStatic {
		// 	continue
		// }

		hasResp := method.ResponseType != nil && len(method.ResponseType.GetName()) > 0
		hasReq := method.RequestType != nil && len(method.RequestType.GetName()) > 0
		hasPathInReq := false

		requestType := ""
		if hasReq {
			requestType = util.ToPascal(method.RequestType.GetName())

			fields := method.RequestType.GetFields()
			// fmt.Println("fields:", len(fields))

			for _, field := range fields {
				fmt.Println("field:", field.Name, field.Type)
			}
		}
		responseType := ""
		if hasResp {
			responseType = util.ToPascal(method.ResponseType.GetName())
		}

		uniqueMethods = append(uniqueMethods, handlerName)
		logicFunc := util.ToPascal(getHandlerName(handler, &method))
		logicFunc = strings.TrimSuffix(logicFunc, "Handler")

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
						LogicFunc:    util.ToPascal(util.ToTitle(topic.Topic)),
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
						LogicFunc:    util.ToPascal(util.ToTitle(topic.Topic)),
					})
				}
			}
		}

		// fmt.Println("handlerName:", handlerName)
		methods = append(methods, types.MethodConfig{
			Method:           method,
			HasBaseProps:     !hasResp && (method.Method == "GET" || method.ReturnsPartial) && (notIn(method.Method, "POST", "PUT", "DELETE", "OPTIONS")),
			HasHTMX:          (method.Method == "GET" || method.ReturnsPartial),
			HasResp:          hasResp,
			HasReq:           hasReq,
			HasPathInReq:     hasPathInReq,
			HasDoc:           method.Doc != nil,
			HasPage:          method.Page != nil,
			HandlerName:      handlerName,
			RequestType:      requestType,
			ResponseType:     responseType,
			LogicName:        logicName,
			LogicType:        util.ToPascal(getLogicName(handler)),
			LogicFunc:        logicFunc, //util.ToPascal(strings.TrimSuffix(handlerName, "Handler")),
			IsSocket:         method.IsSocket,
			TopicsFromClient: topicsFromClient,
			TopicsFromServer: topicsFromServer,
			ReturnsPartial:   method.ReturnsPartial,
			AssetGroup:       assetGroup,
			RequiresSocket:   NewRequiresSocket,
		})
	}

	// b, _ := json.MarshalIndent(methods, "", "  ")
	// fmt.Println("methods", string(b))
	fmt.Println("handler.Name:", handler.Name)

	if handler.Name == "notfound" {
		imports := genHandlerImports(server, handler, builder.ModuleName, true)

		builder.Data["PkgName"] = pkgName
		builder.Data["Imports"] = imports
		builder.Data["Methods"] = methods

		builder.WithOverwriteFile(filepath.Join("app", subDir, "404handler.go"))
		builder.WithRenameFile(filepath.Join("app", subDir, "404handler.go"), filepath.Join("app", subDir, "notfoundhandler.go"))

		fmt.Println("notfound subDir:", subDir)
		if err := builder.genFile(fileGenConfig{
			subdir:       path.Join("app", subDir),
			templateFile: "templates/app/internal/handler/404handler.go.tpl",
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

	builder.WithOverwriteFile(filepath.Join("app", subDir, filename+".go"))
	builder.WithRenameFile(filepath.Join("app", subDir, "handler.go"), filepath.Join("app", subDir, filename+".go"))

	// fmt.Println("handler file:", path.Join("app", subDir))
	// builder.WithRenameFile("internal/handler/handler.go", filepath.Join(subDir, filename+".go"))
	return builder.genFile(fileGenConfig{
		subdir:       path.Join("app", subDir),
		templateFile: "templates/app/internal/handler/handler.go.tpl",
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

	i := imports.New()

	// var hasReq, hasResp, hasBaseProps, hasHTMX, hasTypes, requiresEvents, hasSocket, hasView, hasReturnsPartial bool
	for _, method := range handler.Methods {
		i.AddExternalImport("github.com/labstack/echo/v4")
		i.AddProjectImport(path.Join(moduleName, types.ContextDir))

		if handler.Name == "notfound" {
			i.AddNativeImport("strings")
			i.AddNativeImport("net/http")

			i.AddProjectImport(path.Join(moduleName, theme, "error4x"), "error4x")
			i.AddProjectImport(path.Join(moduleName, getLogicLayoutPath(server)), "pageLayout")
			i.AddProjectImport(path.Join(moduleName, theme, "layouts/baseof"), "baseof")
			i.AddExternalImport("github.com/templwind/soul/htmx")
			i.AddExternalImport("github.com/templwind/templwind")
		} else {
			i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)))
		}

		if method.ReturnsJson {
			i.AddNativeImport("net/http")
			i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
		}

		if method.IsSocket {
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			for _, topic := range method.SocketNode.Topics {
				if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
					i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
				}
			}

			i.AddNativeImport("context")
			i.AddNativeImport("encoding/json")
			i.AddNativeImport("log")
			i.AddProjectImport(path.Join(moduleName, types.EventsDir))
			i.AddExternalImport("github.com/google/uuid")
			i.AddExternalImport("github.com/templwind/soul/webserver/wsmanager")
			i.AddExternalImport("github.com/gobwas/ws", "gobwasWs")
			i.AddExternalImport("github.com/gobwas/ws/wsutil")
		}

		if method.IsStatic || method.IsFullHTMLPage {
			i.AddNativeImport("net/http")

			if omitLogic {
				i.AddNativeImport("strings")
			}

			if omitLogic {
				i.AddProjectImport(path.Join(moduleName, theme, "error4x"), "error4x")
			} else {
				i.AddProjectImport(path.Join(moduleName, theme, "error5x"), "error5x")
			}

			i.AddProjectImport(path.Join(moduleName, getLogicLayoutPath(server)), "pageLayout")
			i.AddProjectImport(path.Join(moduleName, theme, "layouts/baseof"), "baseof")

			i.AddExternalImport("github.com/templwind/soul/htmx")
			i.AddExternalImport("github.com/templwind/templwind")
			if method.IsStatic {
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}
		}

		if method.ReturnsPartial {
			i.AddNativeImport("net/http")
			i.AddExternalImport("github.com/templwind/templwind")
		}

		if method.HasRequestType || method.HasResponseType {
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
		}
	}

	return i.Build()
}

func getHandlerFolderPath(server spec.Server) string {
	folder := server.GetAnnotation(types.GroupProperty)

	if len(folder) == 0 || folder == "/" {
		return types.HandlerDir
	}

	folder = strings.TrimPrefix(folder, "/")
	folder = strings.TrimSuffix(folder, "/")
	folder = strings.ToLower(folder)

	return path.Join(types.HandlerDir, folder)
}
