package internal

import (
	"strconv"
	"time"

	"backend/internal/svc"
	error5x "backend/themes/templwind/error5x"
	baseof "backend/themes/templwind/layouts/baseof"
	footer "backend/themes/templwind/partials/footer"
	head "backend/themes/templwind/partials/head"
	header "backend/themes/templwind/partials/header"

	"github.com/a-h/templ"
	"github.com/labstack/echo/v4"
	"github.com/templwind/soul"
)

func Layout(c echo.Context, svcCtx *svc.ServiceContext, content templ.Component) []soul.OptFunc[baseof.Props] {
	loginUrl := "/auth/login"
	if menu, ok := svcCtx.Config.Menus["login"]; ok && len(menu) > 0 {
		loginUrl = menu[0].URL
	}

	return []soul.OptFunc[baseof.Props]{
		baseof.WithConfig(svcCtx.Config),
		baseof.WithLTRDir("ltr"),
		baseof.WithLangCode("en"),
		baseof.WithHead(head.New(
			head.WithSiteTitle(svcCtx.Config.Site.Title),
			head.WithIsHome(true),
			head.WithCSS(
				svcCtx.Config.Assets.Main.CSS...,
			),
			head.WithJS(
				svcCtx.Config.Assets.Main.JS...,
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

func Error5xLayout(c echo.Context, svcCtx *svc.ServiceContext) []soul.OptFunc[baseof.Props] {
	return []soul.OptFunc[baseof.Props]{
		baseof.WithLTRDir("ltr"),
		baseof.WithLangCode("en"),
		baseof.WithHead(head.New(
			head.WithSiteTitle(svcCtx.Config.Site.Title),
			head.WithIsHome(true),
			head.WithCSS(
				svcCtx.Config.Assets.Main.CSS...,
			),
		)),
		baseof.WithContent(error5x.New(
			error5x.WithErrors(
				"Internal Server Error",
			),
		)),
	}
}
