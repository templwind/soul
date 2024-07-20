package saas

import (
	_ "embed"
	"path"

	"github.com/templwind/soul/tools/soulctl/internal/imports"
	"github.com/templwind/soul/tools/soulctl/internal/types"
)

func buildMain(builder *SaaSBuilder) error {
	var iOptFuncs = make([]imports.OptFunc, 0)
	iOptFuncs = append(iOptFuncs, imports.WithImport("flag"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("fmt"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("net/http"))
	iOptFuncs = append(iOptFuncs, imports.WithSpacer())
	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		builder.ModuleName,
		types.ConfigDir}...,
	)))
	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		builder.ModuleName,
		types.HandlerDir}...,
	)))
	iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
		builder.ModuleName,
		types.ContextDir}...,
	)))

	if hasWorkflow, ok := builder.Data["hasWorkflow"]; ok {
		if hasWorkflow.(bool) {
			iOptFuncs = append(iOptFuncs, imports.WithImport(path.Join([]string{
				builder.ModuleName,
				types.WorkflowDir}...,
			)))
		}
	}

	iOptFuncs = append(iOptFuncs, imports.WithSpacer())
	iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/joho/godotenv/autoload", "_"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/labstack/echo/v4/middleware"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul/conf"))
	iOptFuncs = append(iOptFuncs, imports.WithImport("github.com/templwind/soul/webserver"))

	builder.Data["imports"] = imports.New(iOptFuncs...)

	return builder.genFile(fileGenConfig{
		subdir:       "",
		templateFile: "templates/main.go.tpl",
		data:         builder.Data,
	})
}
