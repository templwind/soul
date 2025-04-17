package new

import (
	"fmt"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/imports"
	"github.com/templwind/soul/tools/soul/pkg/util"
)

const (
	jwtTemplate = ` struct {
		AccessSecret string
		AccessExpire int64
		AccountCookieName string
		UserCookieName    string
		SessionCookieName string
		SecretKey         string
	}
`
	jwtTransTemplate = ` struct {
		Secret     string
		PrevSecret string
	}
`
)

func buildConfig(builder *SaaSBuilder) error {
	authNames := util.GetAuths(builder.Spec)
	var auths []string
	for _, item := range authNames {
		auths = append(auths, fmt.Sprintf("%s %s", item, jwtTemplate))
	}

	jwtTransNames := util.GetJwtTrans(builder.Spec)
	var jwtTransList []string
	for _, item := range jwtTransNames {
		jwtTransList = append(jwtTransList, fmt.Sprintf("%s %s", item, jwtTransTemplate))
	}

	i := imports.New()
	i.AddNativeImport("embed")
	i.AddExternalImport("github.com/templwind/soul/db")
	i.AddExternalImport("github.com/templwind/soul/webserver")
	i.AddExternalImport("github.com/templwind/soul/ratelimiter")

	builder.Data["imports"] = i.Build()
	builder.Data["auth"] = strings.Join(auths, "\n")
	builder.Data["jwtTrans"] = strings.Join(jwtTransList, "\n")

	return builder.genFile(fileGenConfig{
		subdir:       builder.ServiceName + "/internal/config",
		templateFile: "templates/app/internal/config/config.go.tpl",
		data:         builder.Data,
	})
}
