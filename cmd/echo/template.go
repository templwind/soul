package echo

import (
	"fmt"

	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

const (
	category                            = "api"
	configTemplateFile                  = "templates/config.tpl"
	contextTemplateFile                 = "templates/context.tpl"
	etcTemplateFile                     = "templates/etc.tpl"
	handlerTemplateFile                 = "templates/handler.tpl"
	logicTemplateFile                   = "templates/logic.tpl"
	logicTemplTemplateFile              = "templates/logic.templ.tpl"
	mainTemplateFile                    = "templates/main.tpl"
	middlewareImplementCodeFile         = "templates/middleware.tpl"
	routesTemplateFile                  = "templates/routes.tpl"
	routesAdditionTemplateFile          = "templates/route-addition.tpl"
	typesTemplateFile                   = "templates/types.tpl"
	airTemplateFile                     = "templates/air.tpl"
	packageTemplateFile                 = "templates/package.tpl"
	readmeTemplateFile                  = "templates/README.md"
	postcssConfigTemplateFile           = "templates/postcss.tpl"
	tailwindConfigTemplateFile          = "templates/tailwind.tpl"
	tsconfigTemplateFile                = "templates/tsconfig.tpl"
	viteConfigTemplateFile              = "templates/vite.tpl"
	viteEnvTemplateFile                 = "templates/vite-env.tpl"
	stylesTemplateFile                  = "templates/styles.tpl"
	mainTsTemplateFile                  = "templates/main.ts.tpl"
	errorTsTemplateFile                 = "templates/error.ts.tpl"
	gitignoreTemplateFile               = "templates/gitignore.tpl"
	schemaTemplateFile                  = "templates/1_schema.tpl"
	localEnvTemplateFile                = "templates/local.env.tpl"
	makefileTemplateFile                = "templates/makefile.tpl"
	layoutTemplateFile                  = "templates/layout.tpl"
	layoutTemplTemplateFile             = "templates/layout.templ.tpl"
	propsTemplateFile                   = "templates/props.tpl"
	eventsTemplateFile                  = "templates/events.tpl"
	dockerfileTemplateFile              = "templates/dockerfile.tpl"
	dockerComposeTemplateFile           = "templates/docker-compose.tpl"
	notFoundHandlerTemplateFile         = "templates/404handler.tpl"
	migrationsDockerfileTemplateFile    = "templates/migrations-dockerfile.tpl"
	migrationsHealthcheckTemplateFile   = "templates/migrations-healthcheck.tpl"
	migrationsRunMigrationsTemplateFile = "templates/migrations-run-migrations.tpl"
	migrationsDockerComposeTemplateFile = "templates/migrations-docker-compose.tpl"
)

var templates = map[string]string{
	configTemplateFile:                  configTemplate,
	contextTemplateFile:                 contextTemplate,
	etcTemplateFile:                     etcTemplate,
	handlerTemplateFile:                 handlerTemplate,
	logicTemplateFile:                   logicTemplate,
	mainTemplateFile:                    mainTemplate,
	middlewareImplementCodeFile:         middlewareImplementCode,
	routesTemplateFile:                  routesTemplate,
	routesAdditionTemplateFile:          routesAdditionTemplate,
	logicTemplTemplateFile:              logicTemplTemplate,
	typesTemplateFile:                   typesTemplate,
	airTemplateFile:                     airTemplate,
	packageTemplateFile:                 packageTemplate,
	readmeTemplateFile:                  readmeTemplate,
	postcssConfigTemplateFile:           postcssConfigTemplate,
	tailwindConfigTemplateFile:          tailwindConfigTemplate,
	tsconfigTemplateFile:                tsconfigTemplate,
	viteConfigTemplateFile:              viteConfigTemplate,
	viteEnvTemplateFile:                 viteEnvTemplate,
	stylesTemplateFile:                  stylesTemplate,
	mainTsTemplateFile:                  mainTsTemplate,
	errorTsTemplateFile:                 errorTsTemplate,
	gitignoreTemplateFile:               gitignoreTemplate,
	schemaTemplateFile:                  schemaTemplate,
	localEnvTemplateFile:                localEnvTemplate,
	makefileTemplateFile:                makefileTemplate,
	layoutTemplateFile:                  layoutTemplate,
	layoutTemplTemplateFile:             layoutTemplTemplate,
	propsTemplateFile:                   propsTemplate,
	eventsTemplateFile:                  eventsTemplate,
	dockerfileTemplateFile:              dockerfileTemplate,
	dockerComposeTemplateFile:           dockerComposeTemplate,
	notFoundHandlerTemplateFile:         notFoundHandlerTemplate,
	migrationsDockerfileTemplateFile:    migrationsDockerfileTemplate,
	migrationsHealthcheckTemplateFile:   migrationsHealthcheckTemplate,
	migrationsRunMigrationsTemplateFile: migrationsRunMigrationsTemplate,
	migrationsDockerComposeTemplateFile: migrationsDockerComposeTemplate,
}

// Category returns the category of the api files.
func Category() string {
	return category
}

// Clean cleans the generated deployment files.
func Clean() error {
	return pathx.Clean(category)
}

// GenTemplates generates api template files.
func GenTemplates() error {
	return pathx.InitTemplates(category, templates)
}

// RevertTemplate reverts the given template file to the default value.
func RevertTemplate(name string) error {
	content, ok := templates[name]
	if !ok {
		return fmt.Errorf("%s: no such file name", name)
	}
	return pathx.CreateTemplate(category, name, content)
}

// Update updates the template files to the templates built in current goctl.
func Update() error {
	err := Clean()
	if err != nil {
		return err
	}

	return pathx.InitTemplates(category, templates)
}
