package echo

import (
	_ "embed"
	"fmt"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
	// "saas-gen/config"
	// "saas-gen/format"
	// "saas-gen/spec"
)

const (
	configFile = "config"

	jwtTemplate = ` struct {
		AccessSecret string
		AccessExpire int64
	}
`
	jwtTransTemplate = ` struct {
		Secret     string
		PrevSecret string
	}
`
)

//go:embed templates/config.tpl
var configTemplate string

func genConfig(dir string, cfg *config.Config, site *spec.SiteSpec) error {
	filename, err := format.FileNamingFormat(cfg.NamingFormat, configFile)
	if err != nil {
		return err
	}

	authNames := util.GetAuths(site)
	var auths []string
	for _, item := range authNames {
		auths = append(auths, fmt.Sprintf("%s %s", item, jwtTemplate))
	}

	jwtTransNames := util.GetJwtTrans(site)
	var jwtTransList []string
	for _, item := range jwtTransNames {
		jwtTransList = append(jwtTransList, fmt.Sprintf("%s %s", item, jwtTransTemplate))
	}

	imports := genConfigImports()
	// imports := fmt.Sprintf("\"%s/webserver\"", "github.com/templwind/soul")

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          types.ConfigDir,
		filename:        filename + ".go",
		templateName:    "configTemplate",
		category:        category,
		templateFile:    configTemplateFile,
		builtinTemplate: configTemplate,
		data: map[string]string{
			"imports":  imports,
			"auth":     strings.Join(auths, "\n"),
			"jwtTrans": strings.Join(jwtTransList, "\n"),
		},
	})
}

func genConfigImports() string {
	imports := []string{
		fmt.Sprintf("\"%s/db\"", "github.com/templwind/soul"),
		fmt.Sprintf("\"%s/webserver\"", "github.com/templwind/soul"),
	}

	return strings.Join(imports, "\n\t")
}
