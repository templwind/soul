package saas

import (
	"fmt"
	"strings"

	"github.com/templwind/templwind/tools/soul/internal/imports"
	"github.com/templwind/templwind/tools/soul/internal/util"
)

const (
	jwtTemplate = ` struct {
		AccessSecret string
		AccessExpire int64
		AccountCookieName string
		UserCookieName    string
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

	builder.Data["imports"] = imports.New(
		imports.WithImport("sort"),
		imports.WithSpacer(),
		imports.WithImport("github.com/biter777/countries"),
		imports.WithImport("github.com/gosimple/slug"),
		imports.WithImport("github.com/templwind/templwind/db"),
		imports.WithImport("github.com/templwind/templwind/webserver"),
	).String()
	builder.Data["auth"] = strings.Join(auths, "\n")
	builder.Data["jwtTrans"] = strings.Join(jwtTransList, "\n")

	return builder.genFile(fileGenConfig{
		subdir:       "internal/config",
		templateFile: "templates/internal/config/config.go.tpl",
		data:         builder.Data,
	})
}
