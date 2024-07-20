package saas

import (
	_ "embed"
	"fmt"
	"strings"

	"github.com/templwind/soul/tools/soulctl/internal/util"
)

const (
	jwtEtcTemplate = `
  AccessSecret: abcdef0123456789 
  AccessExpire: 84600
`
)

func buildEtc(builder *SaaSBuilder) error {
	builder.Data["host"] = "0.0.0.0"
	builder.Data["port"] = "8888"

	authNames := util.GetAuths(builder.Spec)
	var auths []string
	for _, item := range authNames {
		auths = append(auths, fmt.Sprintf("%s: %s", item, jwtEtcTemplate))
	}
	builder.Data["dsnName"] = strings.ToLower(builder.Spec.Name)
	builder.Data["auth"] = strings.Join(auths, "\n")

	return builder.genFile(fileGenConfig{
		subdir:       "etc/",
		templateFile: "templates/etc/config.yaml.tpl",
		data:         builder.Data,
	})
}
