package echo

import (
	_ "embed"
	"fmt"
	"strconv"
	"strings"

	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
)

const (
	defaultPort = 8888
	etcDir      = "etc"

	jwtEtcTemplate = `
  AccessSecret: abcdef0123456789 
  AccessExpire: 84600
`
)

//go:embed templates/etc.tpl
var etcTemplate string

func genEtc(dir string, cfg *config.Config, site *spec.SiteSpec) error {
	filename, err := format.FileNamingFormat(cfg.NamingFormat, site.Name)
	// fmt.Println("filename:", filename)
	if err != nil {
		return err
	}

	host := "0.0.0.0"
	port := strconv.Itoa(defaultPort)

	authNames := util.GetAuths(site)
	var auths []string
	for _, item := range authNames {
		auths = append(auths, fmt.Sprintf("%s: %s", item, jwtEtcTemplate))
	}

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          etcDir,
		filename:        fmt.Sprintf("%s.yaml", filename),
		templateName:    "etcTemplate",
		category:        category,
		templateFile:    etcTemplateFile,
		builtinTemplate: etcTemplate,
		data: map[string]string{
			"serviceName": site.Name,
			"dsnName":     strings.ToLower(site.Name),
			"host":        host,
			"port":        port,
			"auth":        strings.Join(auths, "\n"),
		},
	})
}
