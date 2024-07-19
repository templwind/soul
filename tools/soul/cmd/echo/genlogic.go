package echo

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

	"github.com/templwind/templwind/tools/soul/internal/types"
	"github.com/templwind/templwind/tools/soul/internal/util"
	"github.com/templwind/templwind/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/api/parser/g4/gen/api"
	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
	"github.com/zeromicro/go-zero/tools/goctl/vars"
)

//go:embed templates/logic.tpl
var logicTemplate string

//go:embed templates/logic.templ.tpl
var logicTemplTemplate string

//go:embed templates/props.tpl
var propsTemplate string

func genLogic(dir, rootPkg string, cfg *config.Config, site *spec.SiteSpec) error {
	for _, server := range site.Servers {
		for _, service := range server.Services {
			for _, handler := range service.Handlers {
				err := genLogicByHandler(dir, rootPkg, cfg, server, handler)
				if err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func addMissingMethods(methods []MethodConfig, dir, subDir, fileName string) error {
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
func generateMethodDefinition(method MethodConfig) string {
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

func genLogicByHandler(dir, rootPkg string, cfg *config.Config, server spec.Server, handler spec.Handler) error {

	logicLayout := server.GetAnnotation("template")

	subDir := getLogicFolderPath(server, handler)
	filename := path.Join(dir, subDir, strings.ToLower(handler.Name)+".go")

	logicType := util.ToPascal(getLogicName(handler))
	// fmt.Println("filename::", filename)

	fileExists := false
	// check if the file exists
	if pathx.FileExists(filename) {
		fileExists = true
	}

	requiresTempl := false
	hasSocket := false

	methods := []MethodConfig{}
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

		if method.Page != nil {
			if key, ok := method.Page.Annotation.Properties["template"]; ok {
				if layoutName, ok := key.(string); ok {
					logicLayout = layoutName
				}
			}
		}

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
				}

				methods = append(methods, MethodConfig{
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
					Topic: Topic{
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
				if !method.ReturnsPartial && !hasResp {
					rParts = append(rParts, "baseProps *[]templwind.OptFunc[baseof.Props]")
				}
				return strings.Join(rParts, ", ")
			}(requestStringParts)

			// fmt.Println("AFTER :: requestString", requestString)

			logicName = strings.ToLower(util.ToCamel(handler.Name))
			call = util.ToPascal(strings.TrimSuffix(handlerName, "Handler"))

			// fmt.Println("handlerName:", handlerName, method.ReturnsPartial)
			methods = append(methods, MethodConfig{
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
			dir,
			subDir,
			strings.ToLower(handler.Name)+".go")
	}

	if requiresTempl {
		templImports := genTemplImports(rootPkg, strings.ToLower(util.ToCamel(logicLayout+"Layout")))

		// fmt.Println("templImports", templImports)
		// templ file first

		if err := genFile(fileGenConfig{
			dir:             dir,
			subdir:          subDir,
			filename:        strings.ToLower(util.ToCamel(handler.Name)) + ".templ",
			templateName:    "logicTemplTemplate",
			category:        category,
			templateFile:    logicTemplTemplateFile,
			builtinTemplate: logicTemplTemplate,
			data: map[string]any{
				"pkgName":      subDir[strings.LastIndex(subDir, "/")+1:],
				"templImports": templImports,
				"templName":    util.ToCamel(handler.Name + "View"),
				"pageTitle":    util.ToTitle(handler.Name),
			},
		}); err != nil {
			return err
		}

		propsImports := genPropsImports(rootPkg)

		if err := genFile(fileGenConfig{
			dir:             dir,
			subdir:          subDir,
			filename:        "props.go",
			templateName:    "logicPropsTemplate",
			category:        category,
			templateFile:    propsTemplateFile,
			builtinTemplate: propsTemplate,
			data: map[string]any{
				"pkgName":   subDir[strings.LastIndex(subDir, "/")+1:],
				"Imports":   propsImports,
				"templName": util.ToCamel(handler.Name + "View"),
			},
		}); err != nil {
			return err
		}
	}

	imports := genLogicImports(server, handler, rootPkg)
	// logicType := strings.Title(getLogicName(handler))

	// sort.Slice(methods, func(i, j int) bool {
	// 	return methods[i].Call < methods[j].Call
	// })

	err := genFile(fileGenConfig{
		dir:             dir,
		subdir:          subDir,
		filename:        strings.ToLower(util.ToCamel(handler.Name)) + ".go",
		templateName:    "logicTemplate",
		category:        category,
		templateFile:    logicTemplateFile,
		builtinTemplate: logicTemplate,
		data: map[string]any{
			"PkgName":   subDir[strings.LastIndex(subDir, "/")+1:],
			"Imports":   imports,
			"LogicType": logicType,
			"Methods":   methods,
			"HasSocket": hasSocket,
		},
	})

	// os.Exit(0)
	return err
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

func genTemplImports(parentPkg, fileName string) string {
	imports := []string{
		// fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.LayoutsDir, fileName)),
	}
	return strings.Join(imports, "\n\t")
}

func genPropsImports(parentPkg string) string {
	imports := []string{
		fmt.Sprintf("\"%s\"\n", "net/http"),
		fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.ConfigDir)),
		fmt.Sprintf("\"%s\"\n", "github.com/a-h/templ"),
		fmt.Sprintf("\"%s\"", "github.com/templwind/templwind"),
	}
	return strings.Join(imports, "\n\t")
}

func genLogicImports(server spec.Server, handler spec.Handler, parentPkg string) string {
	theme := server.GetAnnotation("theme")
	if len(theme) == 0 {
		theme = "themes/templwind"
	} else {
		theme = "themes/" + theme
	}

	var imports []string

	requireTempl := false
	requireTemplwind := false
	requireEcho := false
	hasType := false
	hasSocket := false
	hasEvents := false
	hasReturnsPartial := false
	for _, method := range handler.Methods {
		if method.ReturnsPartial {
			hasReturnsPartial = true
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

	imports = append(imports, fmt.Sprintf("\"%s\"", "context"))
	if hasSocket {
		imports = append(imports, fmt.Sprintf("\"%s\"", "net"))
	}
	imports = append(imports, "\n\n")

	if hasEvents {
		imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.EventsDir)))
	}

	imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.ContextDir)))
	if requireTemplwind {
		imports = append(imports, fmt.Sprintf("baseof \"%s\"", pathx.JoinPackages(parentPkg, theme, "layouts/baseof")))
	}

	if hasType {
		imports = append(imports, fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.TypesDir)))
	}

	imports = append(imports, "\n\n")

	if requireTemplwind || requireTempl {
		imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/a-h/templ"))
	}
	if requireEcho {
		imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/labstack/echo/v4"))
	}
	if requireTemplwind {
		imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/templwind"))
	}
	if hasReturnsPartial {
		// imports = append(imports, fmt.Sprintf("\"%s\"", "github.com/templwind/templwind"))

	}

	// TODO: method fix

	// if requireTemplwind {
	// 	imports = append(imports, "\"github.com/templwind/templwind\"")
	// }
	imports = append(imports, fmt.Sprintf("\"%s/core/logx\"", vars.ProjectOpenSourceURL))
	return strings.Join(imports, "\n\t")
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
