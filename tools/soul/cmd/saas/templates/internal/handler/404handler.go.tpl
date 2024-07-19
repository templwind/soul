package {{.PkgName}}

import (
	{{.Imports}}
)

// NotFoundHandler handles 404 errors and renders the appropriate response.
func NotFoundHandler(svcCtx *svc.ServiceContext) echo.HandlerFunc {
	return func(c echo.Context) error {
		if strings.Contains(c.Request().Header.Get("Accept"), "application/json") {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Resource not found"})
		}

		// intercept htmx requests and just return the error
		if htmx.IsHtmxRequest(c.Request()) {
			return templwind.Render(c, http.StatusOK,
				error4x.New(
					error4x.WithErrors("Page Not Found"),
				),
			)
		}

		// Render HTML 404 page
		return templwind.Render(c, http.StatusNotFound,
			baseof.New(
				baseof.WithLTRDir("ltr"),
				baseof.WithLangCode("en"),
				baseof.WithHead(head.New(
					head.WithSiteTitle(svcCtx.Config.Site.Title),
					head.WithIsHome(true),
					head.WithCSS(svcCtx.Config.Assets.Main.CSS...),
				)),
				baseof.WithHeader(header.New(
					header.WithBrandName(svcCtx.Config.Site.Title),
					header.WithLoginURL("/auth/login"),
					header.WithLoginTitle("Log in"),
					header.WithMenus(svcCtx.Menus),
				)),
				baseof.WithFooter(footer.New(
					footer.WithYear(strconv.Itoa(time.Now().Year())),
				)),
				baseof.WithContent(error4x.New(
					error4x.WithErrors("Page Not Found"),
				)),
			),
		)
	}
}
