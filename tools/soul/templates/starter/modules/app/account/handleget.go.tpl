package settings

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

func (c *Controller) HandleGet(e echo.Context) error {
	account := middleware.AccountFromContext(ctx)
	primaryUser, _ := models.UserByID(ctx.Request().Context(), c.svcCtx.SqlxDB, account.PrimaryUserID)

	return utils.Render(e, 200, New(
		WithConfig(c.svcCtx.Config),
		WithEcho(e),
		WithAccount(account),
		WithPrimaryUser(primaryUser),
	))
}
