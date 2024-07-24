package saas

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
					// fmt.Println("genLogicByHandler failed:", err)
					return err
				}
			}
		}
	}

	return genNotFoundLayout(builder)
}

func addMissingMethods(methods []types.MethodConfig, dir, subDir, fileName string) error {
	// Read the file and look for all the methods and compare with the defined methods
	filePath := path.Join(dir, subDir, fileName)
	fbytes, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("read file failed: %w", err)
	}

	fileContent := string(fbytes)
	var newMethods []string

	for _, method := range methods {
		if !strings.Contains(fileContent, method.LogicFunc) {

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

func genNotFoundLayout(builder *SaaSBuilder) error {
	// write the layout file now
	theme := "templwind"
	layoutPath := path.Join(types.LogicDir, "notfound")
	builder.Data["pkgName"] = "notfound"
	builder.Data["theme"] = theme
	builder.Data["notNotFound"] = false

	layoutFile := path.Join(builder.Dir, layoutPath, "layout.go")
	// only if it exists
	if _, err := os.Stat(layoutFile); err == nil {
		if err := os.Remove(layoutFile); err != nil {
			fmt.Println("error removing file", layoutFile, err)
		}
	}

	// fmt.Println("layoutPath", layoutPath)

	return builder.genFile(fileGenConfig{
		subdir:       layoutPath,
		templateFile: "templates/internal/logic/[logic]/layout.go.tpl",
		data:         builder.Data,
	})
}

func genLogicByHandler(builder *SaaSBuilder, server spec.Server, handler spec.Handler) error {
	subDir := getLogicFolderPath(server, handler)
	filename := path.Join(builder.Dir, subDir, strings.ToLower(handler.Name)+".go")

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
	theme := server.GetAnnotation("theme")
	if len(theme) > 0 {
		builder.Data["theme"] = theme
	}

	layoutFile := path.Join(builder.Dir, layoutPath, "layout.go")
	// only if it exists
	if _, err := os.Stat(layoutFile); err == nil {
		if err := os.Remove(layoutFile); err != nil {
			fmt.Println("error removing file", layoutFile, err)
		}
	}

	if err := builder.genFile(fileGenConfig{
		subdir:       layoutPath,
		templateFile: "templates/internal/logic/[logic]/layout.go.tpl",
		data:         builder.Data,
	}); err != nil {
		fmt.Println("error generating layout.go file", err)
	}

	logicType := util.ToPascal(getLogicName(handler))
	// fmt.Println("filename::", filename)

	fileExists := false
	// check if the file exists
	if pathx.FileExists(filename) {
		fileExists = true
	}

	requiresTempl := false
	hasSocket := false
	uniqueMethods := []string{}
	uniqueTopics := []string{}

	methods := []types.MethodConfig{}
	for _, method := range handler.Methods {
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
		var hasHTMX = (method.Method == "GET" || method.ReturnsPartial)

		handlerName = util.ToPascal(getHandlerName(handler, &method))
		if util.Contains(uniqueMethods, handlerName) {
			continue
		}
		uniqueMethods = append(uniqueMethods, handlerName)

		if !method.IsSocket {
			requiresTempl = true
		} else {
			hasSocket = true
		}

		// skip this method if it is static
		// if method.IsStatic {
		// 	continue
		// }

		// if method.Page != nil {
		// 	if key, ok := method.Page.Annotation.Properties["template"]; ok {
		// 		if layoutName, ok := key.(string); ok {
		// 			logicLayout = layoutName
		// 		}
		// 	}
		// }

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
					Doc:            "",
					LogicName:      logicName,
					LogicType:      logicType,
					LogicFunc:      logicFunc,
					IsSocket:       method.IsSocket,
					Topic: types.Topic{
						InitiatedByServer: !topic.InitiatedByClient,
						InitiatedByClient: topic.InitiatedByClient,
						Const:             "Topic" + util.ToPascal(topic.Topic),
						ResponseType:      strings.ReplaceAll(util.TopicResponseGoTypeName(topic, types.TypesPacket), "*", "&"),
					},
				})
			}
		} else {
			if method.HasResponseType && len(method.ResponseType.GetName()) > 0 {
				resp := util.ResponseGoTypeName(method, types.TypesPacket)
				responseString = "(resp " + resp + ", err error)"
				returnString = "return"
			} else if method.NoOutput {
				responseString = "(err error)"
				returnString = "return"
			} else {
				responseString = "(templ.Component, error)"
				returnString = fmt.Sprintf(`return New(
				WithConfig(l.svcCtx.Config),
				WithRequest(c.Request()),
				WithTitle("%s"),
			), nil`, util.ToTitle(handler.Name))
			}

			if method.HasRequestType && len(method.RequestType.GetName()) > 0 {
				requestString = "req " + util.RequestGoTypeName(method, types.TypesPacket)
			}

			hasResp = method.ResponseType != nil && len(method.ResponseType.GetName()) > 0
			hasReq := method.RequestType != nil && len(method.RequestType.GetName()) > 0

			requestType = ""
			if hasReq {
				requestType = util.ToTitle(method.RequestType.GetName())
			}

			handlerName = util.ToTitle(getHandlerName(handler, &method))

			requestStringParts := []string{
				"c echo.Context",
				requestString,
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

				if method.Method == "GET" &&
					(method.IsFullHTMLPage || method.ReturnsPartial) {
					rParts = append(rParts, "baseProps *[]templwind.OptFunc[baseof.Props]")
				}

				return strings.Join(rParts, ", ")
			}(requestStringParts)

			// fmt.Println("AFTER :: requestString", method.GetName(), requestString)

			logicName = strings.ToLower(util.ToCamel(handler.Name))
			logicFunc = util.ToPascal(strings.TrimSuffix(handlerName, "Handler"))

			// fmt.Println("handlerName:", handlerName, method.ReturnsPartial)
			methods = append(methods, types.MethodConfig{
				Method:         method,
				HasHTMX:        hasHTMX,
				HasResp:        hasResp,
				HasReq:         hasReq,
				HasPathInReq:   hasPathInReq,
				HasDoc:         method.Doc != nil,
				HasPage:        method.Page != nil,
				HandlerName:    handlerName,
				RequestType:    requestType,
				ResponseType:   responseString,
				Request:        requestString,
				ReturnString:   returnString,
				ResponseString: responseString,

				Doc:            "",
				LogicName:      logicName,
				LogicType:      logicType,
				LogicFunc:      logicFunc,
				IsSocket:       method.IsSocket,
				ReturnsPartial: method.ReturnsPartial,
			})
		}
	}

	if fileExists {
		return addMissingMethods(methods,
			builder.Dir,
			subDir,
			strings.ToLower(handler.Name)+".go")
	}

	// set the package name
	builder.Data["pkgName"] = subDir[strings.LastIndex(subDir, "/")+1:]

	if requiresTempl {
		builder.Data["templName"] = util.ToCamel(handler.Name + "View")
		builder.Data["pageTitle"] = util.ToTitle(handler.Name)

		builder.WithRenameFile("internal/logic/logic.templ", filepath.Join(subDir, strings.ToLower(util.ToCamel(handler.Name))+".templ"))
		if err := builder.genFile(fileGenConfig{
			subdir:       subDir,
			templateFile: "templates/internal/logic/[logic]/logic.templ.tpl",
			data:         builder.Data,
		}); err != nil {
			return err
		}

		builder.Data["imports"] = imports.New(
			imports.WithImport("net/http"),
			imports.WithSpacer(),
			imports.WithImport(path.Join([]string{
				builder.ModuleName,
				"internal/config"}...,
			)),
			imports.WithSpacer(),
			imports.WithImport("github.com/a-h/templ"),
			imports.WithImport("github.com/templwind/soul"),
		).String()

		builder.WithRenameFile("internal/logic/props.go", filepath.Join(subDir, "props.go"))
		if err := builder.genFile(fileGenConfig{
			subdir:       subDir,
			templateFile: "templates/internal/logic/[logic]/props.go.tpl",
			data:         builder.Data,
		}); err != nil {
			return err
		}
	}

	builder.Data["pkgName"] = subDir[strings.LastIndex(subDir, "/")+1:]
	builder.Data["imports"] = genLogicImports(server, handler, builder.ModuleName, false)
	builder.Data["LogicType"] = logicType
	builder.Data["methods"] = methods
	builder.Data["hasSocket"] = hasSocket

	builder.WithRenameFile(filepath.Join(subDir, "logic.go"), filepath.Join(subDir, strings.ToLower(util.ToCamel(handler.Name))+".go"))
	return builder.genFile(fileGenConfig{
		subdir:       subDir,
		templateFile: "templates/internal/logic/[logic]/logic.go.tpl",
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
	i.AddExternalImport("github.com/labstack/echo/v4")

	for _, method := range handler.Methods {
		if method.IsFullHTMLPage || method.ReturnsPartial {
			i.AddExternalImport("github.com/a-h/templ")
			i.AddExternalImport("github.com/templwind/templwind")
			i.AddProjectImport(path.Join(moduleName, theme, "layouts/baseof"), "baseof")
		}

		if method.HasRequestType || method.HasResponseType {
			// fmt.Println("method.RequestType", method.RequestType.GetName())
			i.AddProjectImport(path.Join(moduleName, types.TypesDir))
		}

		if method.IsSocket {
			i.AddNativeImport("net")
			// hasSocket = true
			for _, topic := range method.SocketNode.Topics {
				if topic.ResponseType != nil || topic.RequestType != nil {
					i.AddProjectImport(path.Join(moduleName, types.TypesDir))
				}
				if !topic.InitiatedByClient {
					i.AddProjectImport(path.Join(moduleName, types.EventsDir))
				}
			}
		}
	}

	return i.Build()
}
