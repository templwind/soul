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

	if !builder.IsService {
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
	return nil
}

func genHandler(builder *SaaSBuilder, server spec.Server, handler spec.Handler) error {
	handlerName := getHandlerName(handler, nil, true)
	handlerPath := getHandlerFolderPath(server)
	pkgName := toPrefix(strings.ToLower(handlerPath[strings.LastIndex(handlerPath, "/")+1:]))

	hasSocket := false // layoutPath := getLogicLayoutPath(server)
	socketServerTopics := make(map[string]string)
	hasTopicsFromClient := false

	// pubsub
	// hasPubSub := false
	// pubSubTopics := make(map[string]string)

	// for _, method := range handler.Methods {
	// 	fmt.Println("method:", method.Method, method.Route)
	// }

	// logicName := defaultLogicPackage
	if handlerPath != types.HandlerDir {
		handlerName = util.ToPascal(handlerName)
		// logicName = pkgName
	}

	// logicName := strings.ToLower(util.ToCamel(handler.Name))

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
	handlerFile := path.Join(builder.Dir, builder.ServiceName, subDir, filename+".go")
	if _, err := os.Stat(handlerFile); err == nil {
		if err := os.Remove(handlerFile); err != nil {
			fmt.Println("error removing file", handlerFile, err)
		}
	}

	methods := []types.MethodConfig{}
	uniqueMethods := []string{}
	hasHandlerMethods := false
	for _, method := range handler.Methods {
		if method.IsStaticEmbed || method.IsStatic {
			continue
		}

		hasHandlerMethods = true

		handlerName := util.ToPascal(getHandlerName(handler, &method))
		if method.IsPubSub {
			baseName, err := getHandlerBaseName(handler)
			if err != nil {
				panic(err)
			}
			handlerName = util.ToPascal(baseName) + util.ToPascal(method.PubSubNode.Route)
		}

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
		var logicFunc string
		if !method.IsPubSub {
			logicFunc = util.ToPascal(getHandlerName(handler, &method))
		} else {
			logicFunc = util.ToPascal(method.PubSubNode.Route)
		}
		logicFunc = strings.TrimSuffix(logicFunc, "Handler")

		// fmt.Println("method:", method.Method, method.Route)

		pubSubTopic := types.Topic{}
		if method.IsPubSub {
			// hasPubSub = true
			topic := method.PubSubNode.Topic
			if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
				pubSubTopic.HasReqType = true
				pubSubTopic.RequestType = util.ToTitle(topic.RequestType.GetName())
			}
			if topic.ResponseType != nil && len(topic.ResponseType.GetName()) > 0 {
				pubSubTopic.HasRespType = true
				pubSubTopic.ResponseType = util.ToTitle(topic.ResponseType.GetName())
				pubSubTopic.ResponseTopic = topic.ResponseTopic
			}
		}
		// fmt.Println("method:", method)

		topicsFromClient := []types.Topic{}
		topicsFromServer := []types.Topic{}
		if method.IsSocket {
			hasSocket = true

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
					// fmt.Println("SERVER topic.Topic:", topic.Topic, topic.ResponseTopic)
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

					socketServerTopics[topic.GetName()] = "Topic" + util.ToPascal(topic.Topic)
				} else {
					// fmt.Println("CLIENT topic.Topic:", topic.Topic, topic.ResponseTopic)
					var responseTopic string
					if topic.ResponseTopic != "" {
						responseTopic = "Topic" + util.ToPascal(topic.ResponseTopic)
					}

					topicsFromClient = append(topicsFromClient, types.Topic{
						RawTopic:      strings.TrimSpace(topic.Topic),
						Topic:         "Topic" + util.ToPascal(topic.Topic),
						ResponseTopic: responseTopic,
						Name:          topic.GetName(),
						RequestType:   reqType,
						HasReqType:    hasReqType,
						ResponseType:  resType,
						HasRespType:   hasResType,
						LogicFunc:     util.ToPascal(util.ToTitle(topic.Topic)),
					})
				}
			}
			if !hasTopicsFromClient {
				hasTopicsFromClient = len(topicsFromClient) > 0
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
			LogicName:        "logicHandler",
			LogicType:        util.ToPascal(getLogicName(handler)),
			LogicFunc:        logicFunc, //util.ToPascal(strings.TrimSuffix(handlerName, "Handler")),
			IsSocket:         method.IsSocket,
			TopicsFromClient: topicsFromClient,
			TopicsFromServer: topicsFromServer,
			ReturnsPartial:   method.ReturnsPartial,
			AssetGroup:       assetGroup,
			RequiresSocket:   NewRequiresSocket,
			IsPubSub:         method.IsPubSub,
			PubSubTopic:      pubSubTopic,
		})
	}

	// if no methods, return
	if !hasHandlerMethods {
		return nil
	}

	// b, _ := json.MarshalIndent(methods, "", "  ")
	// fmt.Println("methods", string(b))
	// fmt.Println("handler.Name:", handler.Name)

	if !hasSocket {
		hasTopicsFromClient = true
	}

	if handler.Name == "notfound" && !builder.IsService {
		imports := genHandlerImports(server, handler, builder.ModuleName, true, hasTopicsFromClient)

		builder.Data["PkgName"] = pkgName
		builder.Data["Imports"] = imports
		builder.Data["Methods"] = methods

		builder.WithOverwriteFile(filepath.Join(builder.ServiceName, subDir, "404handler.go"))
		builder.WithRenameFile(filepath.Join(builder.ServiceName, subDir, "404handler.go"), filepath.Join(builder.ServiceName, subDir, "notfoundhandler.go"))

		// fmt.Println("notfound subDir:", subDir)
		if err := builder.genFile(fileGenConfig{
			subdir:       path.Join(builder.ServiceName, subDir),
			templateFile: "templates/app/internal/handler/404handler.go.tpl",
			data:         builder.Data,
		}); err != nil {
			return err
		}
		return nil
	}

	imports := genHandlerImports(server, handler, builder.ModuleName, false, hasTopicsFromClient)

	builder.Data["PkgName"] = pkgName
	builder.Data["Imports"] = imports
	builder.Data["Methods"] = methods
	builder.Data["SocketServerTopics"] = socketServerTopics
	builder.Data["HasSocket"] = hasSocket
	// fmt.Println("socketServerTopics:", socketServerTopics)
	// fmt.Println("hasSocket:", hasSocket)

	builder.WithOverwriteFile(filepath.Join(builder.ServiceName, subDir, filename+".go"))
	builder.WithRenameFile(filepath.Join(builder.ServiceName, subDir, "handler.go"), filepath.Join(builder.ServiceName, subDir, filename+".go"))

	// fmt.Println("handler file:", path.Join(builder.ServiceName, subDir))
	// builder.WithRenameFile("internal/handler/handler.go", filepath.Join(subDir, filename+".go"))
	return builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, subDir),
		templateFile: "templates/app/internal/handler/handler.go.tpl",
		data:         builder.Data,
	})
}

func genHandlerImports(server spec.Server, handler spec.Handler, moduleName string, omitLogic bool, hasTopicsFromClient bool) string {
	theme := server.GetAnnotation("theme")
	if len(theme) == 0 {
		theme = "themes/templwind"
	} else {
		theme = "themes/" + theme
	}

	i := imports.New()

	// var hasReq, hasResp, hasBaseProps, hasHTMX, hasTypes, requiresEvents, hasSocket, hasView, hasReturnsPartial bool
	for _, method := range handler.Methods {
		if !method.IsPubSub {
			i.AddExternalImport("github.com/labstack/echo/v4")
		}
		i.AddProjectImport(path.Join(moduleName, types.ContextDir))

		if handler.Name == "notfound" {
			i.AddNativeImport("strings")
			i.AddNativeImport("net/http")

			i.AddProjectImport(path.Join(moduleName, theme, "error4x"), "error4x")
			i.AddProjectImport(path.Join(moduleName, getLogicLayoutPath(server)), "pageLayout")
			i.AddProjectImport(path.Join(moduleName, theme, "layouts/baseof"), "baseof")
			i.AddExternalImport("github.com/templwind/soul/htmx")
			i.AddExternalImport("github.com/templwind/soul")
		} else {
			// fmt.Println("Handler:", strings.ToLower(util.ToCamel(handler.Name))+"Logic")
			if hasTopicsFromClient {
				i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)), "logicHandler")
			}
		}

		if method.ReturnsJson {
			if !method.IsPubSub {
				i.AddNativeImport("net/http")
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}
		}

		if method.IsPubSub {
			i.AddNativeImport("context")
			i.AddNativeImport("encoding/json")
			i.AddNativeImport("log")
			i.AddNativeImport("time")
		}

		if method.IsSocket {
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			for _, topic := range method.SocketNode.Topics {
				if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
					i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
				}
			}

			i.AddNativeImport("bytes")
			i.AddNativeImport("context")
			i.AddNativeImport("encoding/json")
			i.AddNativeImport("log")
			i.AddNativeImport("net")
			i.AddNativeImport("net/http")
			i.AddNativeImport("sync")
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
			i.AddExternalImport("github.com/templwind/soul")
			if method.IsStatic {
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}
		}

		if method.ReturnsPartial {
			i.AddNativeImport("net/http")
			i.AddExternalImport("github.com/templwind/soul")
		}

		if method.HasRequestType || method.HasResponseType {
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			if !method.IsPubSub {
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}
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
