package starter

import (
	"path/filepath"

	"github.com/templwind/templwind/tools/soul/internal/util"
	"github.com/templwind/templwind/tools/soul/templates"
)

func createFileFromTpl(projectBasePath, tplPath, framework string) error {
	// fileName := filepath.Base(tplPath)
	// fmt.Println(filepath.Join(projectBasePath, tplPath))

	return templates.NewWriter(
		templates.WithOutputFilePath(filepath.Join(projectBasePath, tplPath)),
		templates.WithTemplatePath(filepath.Join(baseTplPath, tplPath+".tpl")),
		templates.WithTemplateName(tplPath),
		templates.WithData(getDefaultStruct(projectBasePath, framework)),
	).Write()
}

type defaultSettings struct {
	AppName    string
	ModuleName string
	Namespace  string
	Framework  string
}

var (
	appName    string
	moduleName string
	namespace  string
)

func getDefaultStruct(projectBasePath, framework string) defaultSettings {
	if moduleName == "" {
		// fmt.Println(moduleName
		name, err := util.GetModuleName(projectBasePath)
		if err != nil {
			return defaultSettings{}
		}
		appName = name
		moduleName = name
		namespace = filepath.Base(moduleName)
	}

	return defaultSettings{
		AppName:    appName,
		ModuleName: moduleName,
		Namespace:  namespace,
		Framework:  framework,
	}
}
