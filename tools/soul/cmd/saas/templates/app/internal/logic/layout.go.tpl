package {{.pkgName}}

import (
	"strconv"
	"time"

	"{{ .serviceName }}/internal/svc"
	{{- if .notNotFound }}
	error5x "{{ .serviceName }}/themes/{{ .theme }}/error5x"
	{{ else }}
	error4x "{{ .serviceName }}/themes/{{ .theme }}/error4x"
	{{ end -}}
	baseof "{{ .serviceName }}/themes/{{ .theme }}/layouts/baseof"
	footer "{{ .serviceName }}/themes/{{ .theme }}/partials/footer"
	head "{{ .serviceName }}/themes/{{ .theme }}/partials/head"
	header "{{ .serviceName }}/themes/{{ .theme }}/partials/header"

	{{if .notNotFound }}
	"github.com/a-h/templ"
	{{ end }}
	"github.com/templwind/templwind"
)

{{- if .notNotFound }}
func Layout(svcCtx *svc.ServiceContext, content templ.Component) []templwind.OptFunc[baseof.Props] {
	loginUrl := "/auth/login"
	if menu, ok := svcCtx.Config.Menus["login"]; ok && len(menu) > 0 {
		loginUrl = menu[0].URL
	}

	return []templwind.OptFunc[baseof.Props]{
		baseof.WithLTRDir("ltr"),
		baseof.WithLangCode("en"),
		baseof.WithHead(head.New(
			head.WithSiteTitle(svcCtx.Config.Site.Title),
			head.WithIsHome(true),
			head.WithCSS(
				svcCtx.Config.Assets.{{- .assetGroup -}}.CSS...,
			),
			head.WithJS(
				svcCtx.Config.Assets.{{- .assetGroup -}}.JS...,
			),
		)),
		baseof.WithHeader(header.New(
			header.WithConfig(svcCtx.Config),
			header.WithBrandName(svcCtx.Config.Site.Title),
			header.WithLoginURL(loginUrl),
			header.WithLoginTitle("Log in"),
			header.WithMenus(svcCtx.Menus),
		)),
		baseof.WithMenus(svcCtx.Menus),
		baseof.WithFooter(footer.New(
			footer.WithConfig(svcCtx.Config),
			footer.WithMenus(svcCtx.Menus),
			footer.WithYear(strconv.Itoa(time.Now().Year())),
		)),
		baseof.WithContent(content),
	}
}

func Error5xLayout(svcCtx *svc.ServiceContext) []templwind.OptFunc[baseof.Props] {
	return []templwind.OptFunc[baseof.Props]{
		baseof.WithLTRDir("ltr"),
		baseof.WithLangCode("en"),
		baseof.WithHead(head.New(
			head.WithSiteTitle(svcCtx.Config.Site.Title),
			head.WithIsHome(true),
			head.WithCSS(
				svcCtx.Config.Assets.{{- .assetGroup -}}.CSS...,
			),
		)),
		baseof.WithContent(error5x.New(
			error5x.WithErrors(
				"Internal Server Error",
			),
		)),
	}
}
{{else}}
func Error4xLayout(svcCtx *svc.ServiceContext) []templwind.OptFunc[baseof.Props] {
	loginUrl := "/auth/login"
    loginTitle := "Log in"
	if menu, ok := svcCtx.Config.Menus["login"]; ok && len(menu) > 0 {
		loginUrl = menu[0].URL
        loginTitle = menu[0].Title
	}
    
    return []templwind.OptFunc[baseof.Props]{
		baseof.WithLTRDir("ltr"),
        baseof.WithLangCode("en"),
        baseof.WithHead(head.New(
            head.WithSiteTitle(svcCtx.Config.Site.Title),
            head.WithIsHome(true),
            head.WithCSS(svcCtx.Config.Assets.{{- .assetGroup -}}.CSS...),
        )),
        baseof.WithHeader(header.New(
            header.WithBrandName(svcCtx.Config.Site.Title),
            header.WithLoginURL(loginUrl),
            header.WithLoginTitle(loginTitle),
            header.WithMenus(svcCtx.Menus),
        )),
        baseof.WithFooter(footer.New(
            footer.WithYear(strconv.Itoa(time.Now().Year())),
        )),
        baseof.WithContent(error4x.New(
            error4x.WithErrors("Page Not Found"),
        )),
	}
}
{{ end -}}
