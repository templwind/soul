package account

import (
	"{{ .ModuleName }}/internal/svc"

	"github.com/labstack/echo/v4"
)

func Routes(svcCtx *svc.ServiceContext, parentGroup *echo.Group) {

	// account
	g := parentGroup.Group("/account")

	// account
	ctl := NewController(svcCtx)
	g.GET("", ctl.Index)
	g.POST("", ctl.UpdateAccount)
	g.POST("/change-password", ctl.ChangePassword)

}
