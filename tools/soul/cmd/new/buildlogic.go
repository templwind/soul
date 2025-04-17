package new

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
	"github.com/zeromicro/go-zero/tools/goctl/vars"
)

func buildLogic(builder *SaaSBuilder) error {
	for _, server := range builder.Spec.Servers {
		for _, service := range server.Services {
			for _, handler := range service.Handlers {
				err := genLogicByHandler(builder, server, handler)
				if err != nil {
					fmt.Println("genLogicByHandler failed:", err)
					return err
				}
			}
		}
	}
	return nil
}

func addMissingMethods(builder *SaaSBuilder, methods []types.MethodConfig, dir, subDir, fileName string) error {
	// Read the file and look for all the methods and compare with the defined methods
	filePath := path.Join(dir, builder.ServiceName, subDir, fileName)
	fbytes, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("read file failed: %w", err)
	}

	fileContent := string(fbytes)
	var newMethods []string

	for _, method := range methods {
		// fmt.Printf("Checking for %s\n", fmt.Sprintf("func (l *%s) %s(", method.LogicType, method.LogicFunc))
		if !strings.Contains(fileContent, fmt.Sprintf("func (l *%s) %s(", method.LogicType, method.LogicFunc)) {
			if method.IsPubSub {
				fmt.Println("method.LogicFunc", method.LogicFunc)
			}

			// Add the method definition to the newMethods slice
			newMethods = append(newMethods, generateMethodDefinition(method))
		}
	}

	// If there are new methods to add, append them to the file
	if len(newMethods) > 0 {
		f, err := os.OpenFile(filePath, os.O_APPEND|os.O_WRONLY, 0600)
		if err != nil {
			return fmt.Errorf("open file for writing failed: %w", err)
		}
		defer f.Close()

		for _, newMethod := range newMethods {
			if _, err := f.WriteString(newMethod); err != nil {
				return fmt.Errorf("write to file failed: %w", err)
			}
		}
	}

	return nil
}

// This is the function to generate the method definition based on your template
func generateMethodDefinition(method types.MethodConfig) string {
	tmpl := `{{if .HasDoc}}{{.Doc}}{{end}}
func (l *{{.LogicType}}) {{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
	// todo: add your logic here and delete this line

	{{.ReturnString}}
}
`
	t, err := template.New("method").Parse(tmpl)
	if err != nil {
		panic(fmt.Sprintf("parsing template failed: %v", err))
	}

	var buf bytes.Buffer
	err = t.Execute(&buf, method)
	if err != nil {
		panic(fmt.Sprintf("executing template failed: %v", err))
	}

	return buf.String()
}

func genLogicByHandler(builder *SaaSBuilder, server spec.Server, handler spec.Handler) error {
	subDir := getLogicFolderPath(server, handler)
	filename := path.Join(builder.Dir, builder.ServiceName, subDir, strings.ToLower(handler.Name)+".go")
	//
	// fmt.Println("subDir", subDir)

	// os.Remove(filename)

	hasHandlerMethods := false

	// if false {
	// 	if _, err := os.Stat(filename); err == nil {
	// 		if err := os.Remove(filename); err != nil {
	// 			fmt.Println("error removing file", filename, err)
	// 		}
	// 	}
	// }

	// write the layout file now
	layoutPath := getLogicLayoutPath(server)
	builder.Data["pkgName"] = layoutPath[strings.LastIndex(layoutPath, "/")+1:]
	builder.Data["theme"] = "templwind"
	builder.Data["notNotFound"] = true
	builder.Data["assetGroup"] = "Main"
	theme := server.GetAnnotation("theme")
	if len(theme) > 0 {
		builder.Data["theme"] = theme
	}
	// add the theme to the themes map
	builder.Themes[theme] = theme

	// get the assetGroup
	assetGroup := server.GetAnnotation("assetGroup")
	if len(assetGroup) > 0 {
		builder.Data["assetGroup"] = util.ToTitle(assetGroup)
	}

	logicType := util.ToPascal(getLogicName(handler))
	// fmt.Println("filename::", filename)

	fileExists := false
	// check if the file exists
	if pathx.FileExists(filename) {
		fileExists = true
	}

	hasSocket := false
	uniqueMethods := []string{}
	uniqueTopics := []string{}

	methods := []types.MethodConfig{}
	for _, method := range handler.Methods {
		if method.IsStaticEmbed || method.IsStatic {
			continue
		}

		hasHandlerMethods = true

		var responseString string
		var returnString string
		var requestString string
		var logicName string
		var hasResp bool
		var hasReq bool
		var hasPathInReq bool
		var requestType string
		var handlerName string
		var logicFunc string
		var hasHTMX = (method.Method == "GET" && method.ReturnsPartial)
		var hasRedirect bool

		// handlerName = util.ToPascal(getHandlerName(handler, &method))
		// if util.Contains(uniqueMethods, handlerName) {
		// 	continue
		// }
		handlerName = util.ToPascal(getHandlerName(handler, &method))
		if util.Contains(uniqueMethods, handlerName) {
			continue
		}
		uniqueMethods = append(uniqueMethods, handlerName)

		if method.IsSocket {
			hasSocket = true
		}

		// method types
		if method.IsSocket && method.SocketNode != nil {

			for _, topic := range method.SocketNode.Topics {
				logicFunc = util.ToPascal(topic.Topic)

				// fmt.Println("logicFunc", logicFunc)

				if util.Contains(uniqueTopics, logicFunc) {
					continue
				}
				uniqueTopics = append(uniqueTopics, logicFunc)

				requestString = ""
				responseString = ""
				returnString = ""
				hasReq = false

				if topic.InitiatedByClient {
					resp := util.TopicResponseGoTypeName(topic, types.TypesPacket)
					responseString = "(resp " + resp + ", err error)"
					returnString = "return"

					if topic.RequestType != nil && len(topic.RequestType.GetName()) > 0 {
						hasReq = true
						requestString = "req " + util.TopicRequestGoTypeName(topic, types.TypesPacket)
					}
				} else {
					requestString = "req " + util.TopicResponseGoTypeName(topic, types.TypesPacket)
				}

				methods = append(methods, types.MethodConfig{
					Method:         method,
					HandlerName:    handlerName,
					RequestType:    requestType,
					ResponseType:   responseString,
					Request:        requestString,
					ReturnString:   returnString,
					ResponseString: responseString,
					HasResp:        hasResp,
					HasReq:         hasReq,
					HasDoc:         method.Doc != nil,
					HasPage:        method.Page != nil,

					Doc:       "",
					LogicName: logicName,
					LogicType: logicType,
					LogicFunc: logicFunc,
					IsSocket:  method.IsSocket,
					Topic: types.Topic{
						InitiatedByServer: !topic.InitiatedByClient,
						InitiatedByClient: topic.InitiatedByClient,
						Const:             "Topic" + util.ToPascal(topic.Topic),
						ResponseType:      strings.ReplaceAll(util.TopicResponseGoTypeName(topic, types.TypesPacket), "*", "&"),
					},
				})
			}
		} else {
			builder.Data["pkgName"] = subDir[strings.LastIndex(subDir, "/")+1:]
			builder.Data["hasProps"] = false
			builder.Data["templName"] = pathToName(method.Method, method.Route)
			builder.Data["pageTitle"] = util.ToPascal(pathToName(method.Method, method.Route))

			// fmt.Println("method", method.Method, method.GetName(), method.Route, method.ResponseType, method.NoOutput)
			if method.HasResponseType && len(method.ResponseType.GetName()) > 0 {
				resp := util.ResponseGoTypeName(method, types.TypesPacket)
				responseString = "(resp " + resp + ", err error)"
				returnString = "return"

			} else if method.NoOutput || (method.IsPubSub && !method.HasResponseType) {
				responseString = "(err error)"
				returnString = "return"

			} else if method.ReturnsPlainText {
				responseString = "(resp string, err error)"
				returnString = `return`
			} else if method.ReturnsRedirect {
				hasRedirect = true
				responseString = "(err error)"

				// Using http.Redirect with StatusSeeOther (303) is generally preferred after POST/PUT/DELETE
				// to prevent resubmission if the user refreshes.
				if len(method.RedirectURL) > 0 {
					returnString = fmt.Sprintf(`
					http.Redirect(c.Response().Writer, c.Request(), "%s", http.StatusSeeOther); 
					return`, method.RedirectURL)
				} else {
					// Placeholder URL, should be replaced by actual logic
					returnString = `
					http.Redirect(c.Response().Writer, c.Request(), "/replace-me", http.StatusSeeOther); 
					return`
				}
			}

			if method.HasRequestType && len(method.RequestType.GetName()) > 0 {
				// fmt.Println("method.RequestType", method.RequestType.GetName())
				requestString = "req " + util.RequestGoTypeName(method, types.TypesPacket)
			}

			hasResp = method.ResponseType != nil && len(method.ResponseType.GetName()) > 0
			hasReq := method.RequestType != nil && len(method.RequestType.GetName()) > 0

			requestType = ""
			if hasReq {
				requestType = util.ToTitle(method.RequestType.GetName())
			}

			handlerName = util.ToTitle(getHandlerName(handler, &method))

			var requestStringParts []string
			if method.IsPubSub {
				requestStringParts = []string{
					requestString,
				}
			} else {

				requestStringParts = []string{
					"c echo.Context",
					requestString,
				}
			}
			// fmt.Println("\n\nBEFORE :: requestString", requestString)
			requestString = func(parts []string) string {
				rParts := make([]string, 0)
				for _, part := range parts {
					if len(part) == 0 {
						continue
					}
					rParts = append(rParts, strings.TrimSpace(part))
				}

				return strings.Join(rParts, ", ")
			}(requestStringParts)

			// fmt.Println("AFTER :: requestString", method.GetName(), requestString)

			logicName = strings.ToLower(util.ToCamel(handler.Name))

			var logicFunc string
			if !method.IsPubSub {
				logicFunc = util.ToPascal(getHandlerName(handler, &method))
			} else {
				logicFunc = util.ToPascal(method.PubSubNode.Route)
			}
			logicFunc = strings.TrimSuffix(logicFunc, "Handler")

			// fmt.Println("handlerName:", handlerName, method.ReturnsPartial)
			methods = append(methods, types.MethodConfig{
				Method:           method,
				MethodRawName:    method.GetName(),
				HasHTMX:          hasHTMX,
				HasResp:          hasResp,
				HasReq:           hasReq,
				HasPathInReq:     hasPathInReq,
				HasDoc:           method.Doc != nil,
				HasPage:          method.Page != nil,
				HasBaseProps:     method.IsFullHTMLPage,
				HandlerName:      handlerName,
				RequestType:      requestType,
				ResponseType:     responseString,
				Request:          requestString,
				ReturnString:     returnString,
				ResponseString:   responseString,
				ReturnsPlainText: method.ReturnsPlainText,
				ReturnsFullHTML:  method.IsFullHTMLPage,
				ReturnsPartial:   method.ReturnsPartial,
				ReturnsRedirect:  hasRedirect,
				Doc:              "",
				LogicName:        logicName,
				LogicType:        logicType,
				LogicFunc:        logicFunc,
				IsSocket:         method.IsSocket,
				IsPubSub:         method.IsPubSub,
			})
		}
	}

	if !hasHandlerMethods {
		return nil
	}

	if fileExists {
		return addMissingMethods(
			builder,
			methods,
			builder.Dir,
			subDir,
			strings.ToLower(handler.Name)+".go",
		)
	}

	builder.Data["pkgName"] = subDir[strings.LastIndex(subDir, "/")+1:]
	builder.Data["imports"] = genLogicImports(server, handler, builder.ModuleName, false)
	builder.Data["LogicType"] = logicType
	builder.Data["methods"] = methods
	builder.Data["hasSocket"] = hasSocket

	builder.WithRenameFile(filepath.Join(builder.ServiceName, subDir, "logic.go"), filepath.Join(builder.ServiceName, subDir, strings.ToLower(util.ToCamel(handler.Name))+".go"))
	// fmt.Println("logic subDir", subDir)

	return builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, subDir),
		templateFile: "templates/app/internal/logic/logic.go.tpl",
		data:         builder.Data,
	})
}

func genLogicImports(server spec.Server, handler spec.Handler, moduleName string, isNotFound bool) string {
	theme := server.GetAnnotation("theme")
	if len(theme) == 0 {
		theme = "themes/templwind"
	} else {
		theme = "themes/" + theme
	}

	i := imports.New()

	i.AddNativeImport("context")
	i.AddProjectImport(path.Join(moduleName, types.ContextDir))
	i.AddExternalImport(path.Join(vars.ProjectOpenSourceURL, "/core/logx"))

	for _, method := range handler.Methods {
		// Add net/http import once if any method requires redirection
		if method.ReturnsRedirect {
			i.AddNativeImport("net/http")
		}

		// let's define the rules for the different method types
		switch method.Method {
		case "GET":
			i.AddExternalImport("github.com/labstack/echo/v4")

			if method.HasRequestType || method.HasResponseType {
				i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			}
			if method.IsSocket {
				i.AddNativeImport("net")
				i.AddProjectImport(path.Join(moduleName, types.SessionDir))
				i.AddExternalImport("github.com/templwind/soul/webserver/wsmanager")

				// hasSocket = true
				for _, topic := range method.SocketNode.Topics {
					// if topic.InitiatedByClient {
					if topic.ResponseType != nil || topic.RequestType != nil {
						i.AddProjectImport(path.Join(moduleName, types.TypesDir))
					}
					// i.AddProjectImport(path.Join(moduleName, types.EventsDir))
					// }
				}
			}
		case "POST", "PUT", "PATCH", "DELETE":
			i.AddExternalImport("github.com/labstack/echo/v4")

			if method.HasRequestType || method.HasResponseType {
				i.AddProjectImport(path.Join(moduleName, types.TypesDir))
			}
		case "SUB":
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
		}
	}

	return i.Build()
}
