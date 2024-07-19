package selectaccount

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

func (c *Controller) HandleGet(e echo.Context) error {
	user := middleware.UserFromContext(e)
	accounts, err := models.FindAllAccountsByUserID(e.Request().Context(), c.svcCtx.SqlxDB, user.ID, 0, 0)
	if err != nil {
		return err
	}

	return utils.Render(e, 200, New(
		WithConfig(c.svcCtx.Config),
		WithEcho(e),
		WithAccounts(accounts),
	))
}
