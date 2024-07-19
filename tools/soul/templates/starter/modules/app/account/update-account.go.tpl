package account

import (
	"time"

	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/partials"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind/htmx"
)

func (c *Controller) UpdateAccount(e echo.Context) error {
	account := middleware.AccountFromContext(ctx)

	// bind the model
	account.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

	updateAccountForm := &UpdateAccountForm{}

	err := ctx.Bind(updateAccountForm)
	if err != nil {
		return utils.Render(ctx, 200, partials.Error(
			"Invalid form data",
			err.Error(),
		))
	}

	// validate the account
	err = updateAccountForm.Validate()
	if err != nil {
		return utils.Render(ctx, 200, partials.Error(
			err.Error(),
		))
	}

	// update the account
	updateAccountForm.ToModel(account)

	if err := account.Update(ctx.Request().Context(), c.svcCtx.SqlxDB); err != nil {
		return utils.Render(ctx, 200, partials.Error(
			err.Error(),
		))
	}

	// fire the event trigger
	htmx.Trigger(ctx, "on-update-account-success")

	// return utils.Render(ctx, 200, views.UpdateAccountSuccess())
	return nil
}
