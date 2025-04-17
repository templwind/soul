package new

import (
	_ "embed"
	"path"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/internal/types"
)

func buildMain(builder *SaaSBuilder) error {
	i := imports.New()
	i.AddNativeImport("flag")
	i.AddNativeImport("fmt")
	i.AddNativeImport("embed")
	i.AddNativeImport("net/http")
	i.AddProjectImport(path.Join(builder.ModuleName, types.ConfigDir))
	i.AddProjectImport(path.Join(builder.ModuleName, types.HandlerDir))
	i.AddProjectImport(path.Join(builder.ModuleName, types.ContextDir))
	i.AddProjectImport(path.Join(builder.ModuleName, types.DatabaseDir))

	// Triggers module registration
	i.AddProjectImport(path.Join(builder.ModuleName, types.ModuleInitDir))

	if hasWorkflow, ok := builder.Data["hasWorkflow"]; ok {
		if hasWorkflow.(bool) {
			i.AddProjectImport(path.Join(builder.ModuleName, types.WorkflowDir))
		}
	}

	i.AddExternalImport("github.com/joho/godotenv/autoload", "_")
	i.AddExternalImport("github.com/labstack/echo/v4")
	i.AddExternalImport("github.com/labstack/echo/v4/middleware")
	i.AddExternalImport("github.com/templwind/soul/conf")
	i.AddExternalImport("github.com/templwind/soul/webserver")

	builder.Data["imports"] = i.Build()
	builder.Data["hasEmbeddedFS"] = builder.HasEmbeddedFS

	return builder.genFile(fileGenConfig{
		subdir:       builder.ServiceName + "/",
		templateFile: "templates/app/main.go.tpl",
		data:         builder.Data,
	})
}
