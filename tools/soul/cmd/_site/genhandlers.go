package site

import (
	_ "embed"
	"fmt"
	"path"
	"strings"

	"github.com/templwind/templwind/tools/soul/internal/types"
	"github.com/templwind/templwind/tools/soul/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	goctlutil "github.com/zeromicro/go-zero/tools/goctl/util"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

const defaultLogicPackage = "logic"

//go:embed handler.tpl
var handlerTemplate string

func genHandlers(dir, rootPkg string, cfg *config.Config, site *spec.SiteSpec) error {
	for _, server := range site.Servers {
		for _, service := range server.Services {
			for _, handler := range service.Handlers {
				if err := genHandler(dir, rootPkg, cfg, server, handler); err != nil {
					return err
				}
			}
		}
	}

	return nil
}

func genHandler(dir, rootPkg string, cfg *config.Config, server spec.Server, handler spec.Handler) error {
	handlerName := getHandlerName(handler)
	handlerPath := getHandlerFolderPath(server)
	pkgName := handlerPath[strings.LastIndex(handlerPath, "/")+1:]
	logicName := defaultLogicPackage
	if handlerPath != types.HandlerDir {
		handlerName = strings.Title(handlerName)
		logicName = pkgName
	}
	filename, err := format.FileNamingFormat(cfg.NamingFormat, handlerName)
	if err != nil {
		return err
	}

	hasResp := handler.ResponseType != nil && len(handler.ResponseType.GetName()) > 0
	hasReq := handler.RequestType != nil && len(handler.RequestType.GetName()) > 0

	requestType := ""
	if hasReq {
		requestType = goctlutil.Title(handler.RequestType.GetName())
	}

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          getHandlerFolderPath(server),
		filename:        filename + ".go",
		templateName:    "handlerTemplate",
		category:        category,
		templateFile:    handlerTemplateFile,
		builtinTemplate: handlerTemplate,
		data: map[string]any{
			"PkgName":        pkgName,
			"ImportPackages": genHandlerImports(server, handler, rootPkg),
			"HandlerName":    handlerName,
			"RequestType":    requestType,
			"LogicName":      logicName,
			"LogicType":      strings.Title(getLogicName(handler)),
			"Call":           strings.Title(strings.TrimSuffix(handler.Name, "Handler")),
			"HasResp":        hasResp,
			"HasRequest":     hasReq,
			"HasDoc":         false,
			"Doc":            "",
		},
	})
}

func genHandlerImports(server spec.Server, handler spec.Handler, parentPkg string) string {
	imports := []string{
		fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, getLogicFolderPath(server))),
		fmt.Sprintf("\"%s\"", pathx.JoinPackages(parentPkg, types.ContextDir)),
	}
	if handler.RequestType != nil && len(handler.RequestType.GetName()) > 0 {
		imports = append(imports, fmt.Sprintf("\"%s\"\n", pathx.JoinPackages(parentPkg, types.TypesDir)))
	}

	return strings.Join(imports, "\n\t")
}

func getHandlerBaseName(route spec.Handler) (string, error) {
	name := route.Name
	name = strings.TrimSpace(name)
	name = strings.TrimSuffix(name, "handler")
	name = strings.TrimSuffix(name, "Handler")

	return name, nil
}

func getHandlerFolderPath(server spec.Server) string {
	folder := server.GetAnnotation(types.GroupProperty)
	if len(folder) == 0 || folder == "/" {
		return types.HandlerDir
	}

	folder = strings.TrimPrefix(folder, "/")
	folder = strings.TrimSuffix(folder, "/")

	return path.Join(types.HandlerDir, folder)
}

func getHandlerName(handler spec.Handler) string {
	baseName, err := getHandlerBaseName(handler)
	if err != nil {
		panic(err)
	}

	return baseName + "Handler"
}

func getLogicName(handler spec.Handler) string {
	baseName, err := getHandlerBaseName(handler)
	if err != nil {
		panic(err)
	}

	return baseName + "Logic"
}
