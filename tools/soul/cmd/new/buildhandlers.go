package new

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
	return nil
}

func genHandler(builder *SaaSBuilder, server spec.Server, handler spec.Handler) error {
	handlerName := getHandlerName(handler, nil, true)
	handlerPath := getHandlerFolderPath(server)
	pkgName := toPrefix(strings.ToLower(handlerPath[strings.LastIndex(handlerPath, "/")+1:]))

	prefix := server.GetAnnotation(types.PrefixProperty)
	// fmt.Println("--------------------------------")
	// fmt.Println("prefix:", prefix)
	// fmt.Println("handlerPath:", handlerPath)
	// fmt.Println("handlerName:", handlerName)
	// os.Exit(1)
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

		method.Prefix = prefix

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

		reqIsPointer := false
		reqIsArray := false
		requestType := ""
		if hasReq {
			// fmt.Println("RequestType:", method.RequestType.GetName())

			// check to see if it's a pointer or an array
			// so we can prepend * or [] after the type name
			if strings.HasPrefix(method.RequestType.GetName(), "*") {
				reqIsPointer = true
			} else if strings.HasPrefix(method.RequestType.GetName(), "[]") {
				reqIsArray = true
			}
			requestType = util.ToPascal(method.RequestType.GetName())

			// fields := method.RequestType.GetFields()
			// // fmt.Println("fields:", len(fields))

			// for _, field := range fields {
			// 	fmt.Println("field:", field.Name, field.Type)
			// }
		}
		// fmt.Println("RequestType:", requestType)

		respIsPointer := false
		respIsArray := false
		responseType := ""
		if hasResp {
			if strings.HasPrefix(method.ResponseType.GetName(), "*") {
				respIsPointer = true
			} else if strings.HasPrefix(method.ResponseType.GetName(), "[]") {
				respIsArray = true
			}
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

		// var logicFunc string
		// if !method.IsPubSub {
		// 	logicFunc = util.ToPascal(pathToName(method.Method, method.Route))
		// } else {
		// 	logicFunc = util.ToPascal(method.PubSubNode.Route)
		// }
		// logicFunc = strings.TrimSuffix(logicFunc, "Handler")

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
				var topicReqIsPointer, topicReqIsArray bool
				var topicRespIsPointer, topicRespIsArray bool
				if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
					hasReqType = true

					// fmt.Println("topic.RequestType.GetName():", topic.RequestType.GetName())
					if strings.HasPrefix(topic.RequestType.GetName(), "*") {
						topicReqIsPointer = true
					} else if strings.HasPrefix(topic.RequestType.GetName(), "[]") {
						topicReqIsArray = true
					}
					reqType = util.ToTitle(topic.RequestType.GetName())
				}
				if topic.ResponseType != nil && len(topic.ResponseType.GetName()) > 0 {
					hasResType = true
					if strings.HasPrefix(topic.ResponseType.GetName(), "*") {
						topicRespIsPointer = true
					} else if strings.HasPrefix(topic.ResponseType.GetName(), "[]") {
						topicRespIsArray = true
					}
					resType = util.ToTitle(topic.ResponseType.GetName())
				}

				if !topic.InitiatedByClient {
					// fmt.Println("SERVER topic.Topic:", topic.Topic, topic.ResponseTopic)
					topicsFromServer = append(topicsFromServer, types.Topic{
						RawTopic:           strings.TrimSpace(topic.Topic),
						Topic:              "Topic" + util.ToPascal(topic.Topic),
						Name:               topic.GetName(),
						RequestType:        reqType,
						HasReqType:         hasReqType,
						HasPointerRequest:  topicReqIsPointer,
						HasArrayRequest:    topicReqIsArray,
						ResponseType:       resType,
						HasRespType:        hasResType,
						HasPointerResponse: topicRespIsPointer,
						HasArrayResponse:   topicRespIsArray,
						LogicFunc:          util.ToPascal(util.ToTitle(topic.Topic)),
					})

					socketServerTopics[topic.GetName()] = "Topic" + util.ToPascal(topic.Topic)
				} else {
					// fmt.Println("CLIENT topic.Topic:", topic.Topic, topic.ResponseTopic)
					var responseTopic string
					if topic.ResponseTopic != "" {
						responseTopic = "Topic" + util.ToPascal(topic.ResponseTopic)
					}

					topicsFromClient = append(topicsFromClient, types.Topic{
						RawTopic:           strings.TrimSpace(topic.Topic),
						Topic:              "Topic" + util.ToPascal(topic.Topic),
						ResponseTopic:      responseTopic,
						Name:               topic.GetName(),
						RequestType:        reqType,
						HasReqType:         hasReqType,
						ResponseType:       resType,
						HasRespType:        hasResType,
						HasPointerRequest:  topicReqIsPointer,
						HasArrayRequest:    topicReqIsArray,
						HasPointerResponse: topicRespIsPointer,
						HasArrayResponse:   topicRespIsArray,
						LogicFunc:          util.ToPascal(util.ToTitle(topic.Topic)),
					})
				}
			}
			if !hasTopicsFromClient {
				hasTopicsFromClient = len(topicsFromClient) > 0
			}
		}

		// fmt.Println("handlerName:", handlerName)
		methods = append(methods, types.MethodConfig{
			Method:             method,
			MethodRawName:      method.Method,
			HasBaseProps:       !hasResp && (method.Method == "GET" && method.IsFullHTMLPage) && (notIn(method.Method, "POST", "PUT", "DELETE", "OPTIONS")),
			HasHTMX:            (method.Method == "GET" || method.ReturnsPartial),
			HasResp:            hasResp,
			HasReq:             hasReq,
			HasPathInReq:       hasPathInReq,
			HasDoc:             method.Doc != nil,
			HasPage:            method.Page != nil,
			HandlerName:        handlerName,
			RequestType:        requestType,
			HasPointerRequest:  reqIsPointer,
			HasArrayRequest:    reqIsArray,
			ResponseType:       responseType,
			HasPointerResponse: respIsPointer,
			HasArrayResponse:   respIsArray,
			LogicName:          "logicHandler",
			LogicType:          util.ToPascal(getLogicName(handler)),
			LogicFunc:          logicFunc, //util.ToPascal(strings.TrimSuffix(handlerName, "Handler")),
			IsSocket:           method.IsSocket,
			IsDownload:         method.IsDownload,
			TopicsFromClient:   topicsFromClient,
			TopicsFromServer:   topicsFromServer,
			ReturnsPartial:     method.ReturnsPartial,
			ReturnsImage:       method.ReturnsImage,
			ReturnsPlainText:   method.ReturnsPlainText,
			ReturnsRedirect:    method.ReturnsRedirect,
			AssetGroup:         assetGroup,
			RequiresSocket:     NewRequiresSocket,
			IsPubSub:           method.IsPubSub,
			PubSubTopic:        pubSubTopic,
			IsSSE:              method.IsSSE,
			ReturnsNoOutput:    method.NoOutput,
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
		// let's define the rules for the different method types
		switch method.Method {
		case "GET":
			// GET
			// get can return full html page, json, partial, nothing or can be a websocket or pubsub

			i.AddNativeImport("net/http")
			i.AddProjectImport(path.Join(moduleName, types.ContextDir))
			i.AddExternalImport("github.com/labstack/echo/v4")

			if method.IsSSE {
				i.AddNativeImport("time")
				i.AddNativeImport("sync")
				i.AddNativeImport("fmt")
				i.AddNativeImport("encoding/json")

				// i.AddProjectImport(path.Join(moduleName, types.TypesDir))
				i.AddProjectImport(path.Join(moduleName, types.ContextDir))
				i.AddProjectImport(path.Join(moduleName, types.SessionDir))

				i.AddExternalImport("github.com/google/uuid")

				continue
			}

			if method.IsSocket {
				i.AddProjectImport(path.Join(moduleName, types.TypesDir))
				i.AddProjectImport(path.Join(moduleName, types.SessionDir))
				for _, topic := range method.SocketNode.Topics {
					if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 && topic.InitiatedByClient {
						i.AddExternalImport("github.com/templwind/soul/webserver/httpx")

					}
				}

				// set the logic handler based on the handler name
				if hasTopicsFromClient {
					i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)), "logicHandler")
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
				continue
			}

			// set the logic handler based on the handler name
			i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)), "logicHandler")

			if method.HasRequestType {
				i.AddProjectImport(path.Join(moduleName, types.TypesDir))
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}

			continue

		case "POST", "PUT", "PATCH", "DELETE":
			if method.ReturnsRedirect {
				i.AddExternalImport("github.com/templwind/soul")
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}

			// POST
			// post can return full html page, json or partial.

			i.AddProjectImport(path.Join(moduleName, types.ContextDir))
			i.AddExternalImport("github.com/labstack/echo/v4")

			// set the logic handler based on the handler name
			i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)), "logicHandler")

			if method.HasRequestType {
				i.AddNativeImport("net/http")
				i.AddProjectImport(path.Join(moduleName, types.TypesDir))
				i.AddExternalImport("github.com/templwind/soul/webserver/httpx")
			}

			if method.ReturnsJson || method.NoOutput {
				i.AddNativeImport("net/http")
			}

			continue

		case "SUB":
			// SUB
			// sub is a pubsub topic

			i.AddNativeImport("log")
			i.AddNativeImport("encoding/json")
			i.AddNativeImport("time")
			i.AddNativeImport("context")
			i.AddProjectImport(path.Join(moduleName, types.ContextDir))
			i.AddProjectImport(path.Join(moduleName, getLogicFolderPath(server, handler)), "logicHandler")
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))

			continue
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
