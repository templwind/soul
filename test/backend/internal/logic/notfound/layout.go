package notfound

import (
	"strconv"
	"time"

	"backend/internal/svc"
	error4x "backend/themes/templwind/error4x"
	baseof "backend/themes/templwind/layouts/baseof"
	footer "backend/themes/templwind/partials/footer"
	head "backend/themes/templwind/partials/head"
	header "backend/themes/templwind/partials/header"

	"github.com/labstack/echo/v4"
	"github.com/templwind/soul"
)

func Error4xLayout(c echo.Context, svcCtx *svc.ServiceContext) []soul.OptFunc[baseof.Props] {
	loginUrl := "/auth/login"
	loginTitle := "Log in"
	if menu, ok := svcCtx.Config.Menus["login"]; ok && len(menu) > 0 {
		loginUrl = menu[0].URL
		loginTitle = menu[0].Title
	}

	return []soul.OptFunc[baseof.Props]{
		baseof.WithLTRDir("ltr"),
		baseof.WithLangCode("en"),
		baseof.WithHead(head.New(
			head.WithSiteTitle(svcCtx.Config.Site.Title),
			head.WithIsHome(true),
			head.WithCSS(svcCtx.Config.Assets.Main.CSS...),
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
