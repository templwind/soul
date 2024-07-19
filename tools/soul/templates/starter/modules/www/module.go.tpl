package www

import (
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/modules/www/index"
	"{{ .ModuleName }}/modules/www/login"
	"{{ .ModuleName }}/modules/www/register"

	"github.com/labstack/echo/v4"
)

func Module() *WwwModule {
	return &WwwModule{}
}

type WwwModule struct {
	Name string
}

func (m *WwwModule) Register(svcCtx *svc.ServiceContext, e *echo.Echo) error {
	m.Name = "www"

	// empty group for home
	// matches /
	g := e.Group("")
	g.GET("", index.NewController(svcCtx).HandleGet)

	// login
	g.GET("/login", login.NewController(svcCtx).HandleGet)
	g.POST("/login", login.NewController(svcCtx).HandlePost)

	// register
	g.GET("/register", register.NewController(svcCtx).HandleGet)
	g.POST("/register", register.NewController(svcCtx).HandleGet)

	// group.GET("", func(e echo.Context) error {
	// 	return htmx.Redirect(
	// 		e.Response().Writer,
	// 		e.Request(),
	// 		"/login",
	// 	)
	// })

	return nil
}
