package saas

import (
	"bytes"
	_ "embed"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/internal/util"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/api/parser/g4/gen/api"
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
	return nil
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
		if !strings.Contains(fileContent, method.Call) {

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
func (l *{{.LogicType}}) {{.Call}}({{.Request}}) {{.ResponseType}} {
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

	// fmt.Println("genLogicByHandler", handler.Name)

	// logicLayout := server.GetAnnotation("template")

	subDir := getLogicFolderPath(server, handler)
	filename := path.Join(builder.Dir, subDir, strings.ToLower(handler.Name)+".go")

	logicType := util.ToPascal(getLogicName(handler))
	// fmt.Println("filename::", filename)

	fileExists := false
	// check if the file exists
	if pathx.FileExists(filename) {
		fileExists = true
	}

	requiresTempl := false
	hasSocket := false

	methods := []types.MethodConfig{}
	for _, method := range handler.Methods {

		if !method.IsSocket {
			requiresTempl = true
		} else {
			hasSocket = true
		}

		// skip this method if it is static
		if method.IsStatic {
			continue
		}

		// if method.Page != nil {
		// 	if key, ok := method.Page.Annotation.Properties["template"]; ok {
		// 		if layoutName, ok := key.(string); ok {
		// 			logicLayout = layoutName
		// 		}
		// 	}
		// }

		var responseString string
		var returnString string
		var requestString string
		var logicName string
		var hasResp bool
		var hasReq bool
		var requestType string
		var handlerName string
		var call string

		if method.IsSocket && method.SocketNode != nil {
			for _, topic := range method.SocketNode.Topics {
				call = util.ToPascal(topic.Topic)

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
					Call:           call,
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
			if method.ResponseType != nil && len(method.ResponseType.GetName()) > 0 {
				resp := util.ResponseGoTypeName(method, types.TypesPacket)
				responseString = "(resp " + resp + ", err error)"
				returnString = "return"
			} else {
				responseString = "(templ.Component, error)"
				returnString = fmt.Sprintf(`return New(
				WithConfig(l.svcCtx.Config),
				WithRequest(c.Request()),
				WithTitle("%s"),
			), nil`, util.ToTitle(handler.Name))
			}

			if method.RequestType != nil && len(method.RequestType.GetName()) > 0 {
				requestString = "req " + util.RequestGoTypeName(method, types.TypesPacket)
			}

			hasResp = method.ResponseType != nil && len(method.ResponseType.GetName()) > 0
			hasReq := method.RequestType != nil && len(method.RequestType.GetName()) > 0

			requestType = ""
			if hasReq {
				requestType = util.ToTitle(method.RequestType.GetName())
			}

			handlerName = util.ToTitle(getHandlerName(handler, &method, false))

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
				if !method.ReturnsPartial && !hasResp {
					rParts = append(rParts, "baseProps *[]templwind.OptFunc[baseof.Props]")
				}
				return strings.Join(rParts, ", ")
			}(requestStringParts)

			// fmt.Println("AFTER :: requestString", requestString)

			logicName = strings.ToLower(util.ToCamel(handler.Name))
			call = util.ToPascal(strings.TrimSuffix(handlerName, "Handler"))

			// fmt.Println("handlerName:", handlerName, method.ReturnsPartial)
			methods = append(methods, types.MethodConfig{
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
				Call:           call,
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
			templateFile: "templates/internal/logic/logic.templ.tpl",
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
			templateFile: "templates/internal/logic/props.go.tpl",
			data:         builder.Data,
		}); err != nil {
			return err
		}
	}

	builder.Data["pkgName"] = subDir[strings.LastIndex(subDir, "/")+1:]
	builder.Data["imports"] = genLogicImports(server, handler, builder.ModuleName)
	builder.Data["LogicType"] = logicType
	builder.Data["methods"] = methods
	builder.Data["hasSocket"] = hasSocket

	builder.WithRenameFile(filepath.Join(subDir, "logic.go"), filepath.Join(subDir, strings.ToLower(util.ToCamel(handler.Name))+".go"))
	return builder.genFile(fileGenConfig{
		subdir:       subDir,
		templateFile: "templates/internal/logic/logic.go.tpl",
		data:         builder.Data,
	})
}

func getLogicFolderPath(server spec.Server, handler spec.Handler) string {
	folder := server.GetAnnotation(types.GroupProperty)
	if len(folder) == 0 || folder == "/" {
		return types.LogicDir
	}
	folder = strings.TrimPrefix(folder, "/")
	folder = strings.TrimSuffix(folder, "/")
	// get the last part of the folder
	parts := strings.Split(folder, "/")
	// format the last part of the folder
	parts[len(parts)-1] = strings.ToLower(util.ToCamel(parts[len(parts)-1]))
	folder = filepath.Join(parts...)

	return path.Join(types.LogicDir, folder, strings.ToLower(util.ToCamel(handler.Name)))
}

func genLogicImports(server spec.Server, handler spec.Handler, moduleName string) string {
	theme := server.GetAnnotation("theme")
	if len(theme) == 0 {
		theme = "themes/templwind"
	} else {
		theme = "themes/" + theme
	}

	// var imports []string
	var iOptFuncs = make([]imports.OptFunc, 0)

	requireTempl := false
	requireTemplwind := false
	requireEcho := false
	hasType := false
	hasSocket := false
	hasEvents := false
	for _, method := range handler.Methods {
		if method.ReturnsPartial {
			requireEcho = true
			requireTempl = true
			continue
		}

		// show when the response type is empty
		if (method.ResponseType == nil || method.ReturnsPartial) && !method.IsSocket {
			requireTemplwind = true
			requireEcho = true
		}

		if (method.ResponseType != nil || method.RequestType != nil) && !method.ReturnsPartial {
			hasType = true
			requireEcho = true
		}

		if method.IsSocket {
			hasSocket = true
			for _, topic := range method.SocketNode.Topics {
				if topic.ResponseType != nil || topic.RequestType != nil {
					hasType = true
				}
				if !topic.InitiatedByClient {
					hasEvents = true
				}
			}
		}
	}

	iOptFuncs = append(iOptFuncs, imports.WithImport("context"))

	if hasSocket {
		iOptFuncs = append(iOptFuncs, imports.WithImport("net"))

	}

	iOptFuncs = append(iOptFuncs, imports.WithSpacer())

	if hasEvents {

		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"internal/events"}...,
		)))
	}

	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		moduleName,
		"internal/svc"}...,
	)))
	if requireTemplwind {

		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"layouts/baseof"}...,
		)))
	}

	if hasType {

		iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
			moduleName,
			theme,
			"internal/types"}...,
		)))
	}

	iOptFuncs = append(iOptFuncs, imports.WithSpacer())

	if requireTemplwind || requireTempl {

		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/a-h/templ"))
	}
	if requireEcho || hasSocket {

		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/labstack/echo/v4"))
	}
	if requireTemplwind {

		iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul"))
	}

	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		vars.ProjectOpenSourceURL,
		"/core/logx"}...,
	)))

	// return strings.Join(imports, "\n\t")
	return imports.New(iOptFuncs...).String()
}

func onlyPrimitiveTypes(val string) bool {
	fields := strings.FieldsFunc(val, func(r rune) bool {
		return r == '[' || r == ']' || r == ' '
	})

	for _, field := range fields {
		if field == "map" {
			continue
		}
		// ignore array dimension number, like [5]int
		if _, err := strconv.Atoi(field); err == nil {
			continue
		}
		if !api.IsBasicType(field) {
			return false
		}
	}

	return true
}

func shallImportTypesPackage(method spec.Method) bool {

	if method.RequestType != nil && len(method.RequestType.GetName()) > 0 {
		return true
	}

	// fmt.Println("method.RequestType.GetName()", method.RequestType.GetName())

	respTypeName := method.ResponseType
	if method.ResponseType == nil || len(respTypeName.GetName()) == 0 {
		return false
	}

	if onlyPrimitiveTypes(respTypeName.GetName()) {
		return false
	}

	return true
}
