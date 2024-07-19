package echo

import (
	_ "embed"
	"strings"

	"github.com/templwind/templwind/tools/soul/pkg/site/spec"
)

//go:embed templates/air.tpl
var airTemplate string

func genAir(dir string, site *spec.SiteSpec) error {
	serviceName := strings.ToLower(site.Name)

	return genFile(fileGenConfig{
		dir:             dir,
		filename:        ".air.toml",
		templateName:    "airTemplate",
		category:        category,
		templateFile:    airTemplateFile,
		builtinTemplate: airTemplate,
		data: map[string]string{
			"serviceName": serviceName,
		},
	})
}
