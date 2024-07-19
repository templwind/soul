package changepassword

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

type Controller struct {
	svcCtx *svc.ServiceContext
}

func NewController(svcCtx *svc.ServiceContext) *Controller {
	return &Controller{
		svcCtx: svcCtx,
	}
}

func (c *Controller) HandleGet(e echo.Context) error {
	account := middleware.AccountFromContext(e)
	primaryUser, _ := models.UserByID(e.Request().Context(), c.svcCtx.SqlxDB, account.PrimaryUserID)

	return utils.Render(ctx, 200, tpl(e, c.svcCtx.Config, account, primaryUser))
}
