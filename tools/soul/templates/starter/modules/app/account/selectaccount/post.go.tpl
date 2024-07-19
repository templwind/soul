package selectaccount

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/partials"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

func (c *Controller) HandlePost(e echo.Context) error {
	accountID := e.Param("id")
	user := middleware.UserFromContext(e)

	// how many accounts are associated with this?
	userAccount, err := models.UserAccountByUserIDAccountID(e.Request().Context(), c.svcCtx.SqlxDB, user.ID, accountID)
	if err != nil && err != models.ErrDoesNotExist {
		return utils.Render(e, 200, partials.Error(err.Error()))
	}

	err = middleware.SetAccountToken(e, c.svcCtx, userAccount)
	if err != nil {
		return utils.Render(e, 200, partials.Error(err.Error()))
	}

	return utils.Redirect(e, "/app")
}
