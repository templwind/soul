package app

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/modules/app/account"
	"{{ .ModuleName }}/modules/app/account/changepassword"
	"{{ .ModuleName }}/modules/app/account/selectaccount"
	"{{ .ModuleName }}/modules/app/billing"
	"{{ .ModuleName }}/modules/app/dashboard"
	"{{ .ModuleName }}/modules/app/settings"

	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind/htmx"
)

func Module() *AppModule {
	return &AppModule{}
}

type AppModule struct {
	Name string
}

func (m *AppModule) Register(svcCtx *svc.ServiceContext, e *echo.Echo) error {
	m.Name = "app"

	g := e.Group("/app",
		middleware.LoadAuthContextFromCookie(svcCtx),
		middleware.AuthGuard,
		middleware.LoadAccountContextFromCookie(svcCtx),
		middleware.AccountGuard,
	)

	// logout
	g.GET("/logout", func(e echo.Context) error {
		middleware.ClearCookies(e,
			middleware.AuthCookieName,    // clear auth cookie
			middleware.AccountCookieName, // clear account cookie
		)
		return htmx.Redirect(
			e.Response().Writer,
			e.Request(),
			"/login",
		)
	})

	// dashboard
	g.GET("/dashboard", dashboard.NewController(svcCtx).HandleGet)

	// settings
	g.GET("/settings", settings.NewController(svcCtx).HandleGet)
	g.GET("/settings/change-password", changepassword.NewController(svcCtx).HandleGet)
	
	// account
	g.GET("/account", account.NewController(svcCtx).HandleGet)
	
	// billing
	g.GET("/account/billing", billing.NewController(svcCtx).HandleGet)
	
	// select-account
	g.GET("/account/select-account", selectaccount.NewController(svcCtx).HandleGet)
	g.POST("/account/select-account/:id", selectaccount.NewController(svcCtx).HandlePost)

	return nil
}