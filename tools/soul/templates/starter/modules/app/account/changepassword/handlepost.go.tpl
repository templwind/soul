package changepassword

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/partials"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind/htmx"
)

func (c *Controller) ChangePassword(e echo.Context) error {
	account := middleware.AccountFromContext(ctx)
	user, _ := models.UserByID(ctx.Request().Context(), c.svcCtx.SqlxDB, account.PrimaryUserID)

	changePasswordForm := ChangePasswordForm{}
	ctx.Bind(&changePasswordForm)

	// authenicate the user
	if !user.ValidatePassword(changePasswordForm.CurrentPassword) {
		return utils.Render(ctx, 200, partials.Error(
			"Your current password is incorrect",
		))
	}

	// validate the account
	err := changePasswordForm.Validate()
	if err != nil {
		return utils.Render(ctx, 200, partials.Error(
			err.Error(),
		))
	}

	if err := user.UpdateWithPassword(ctx.Request().Context(), c.svcCtx.SqlxDB, changePasswordForm.NewPassword); err != nil {
		return utils.Render(ctx, 200, partials.Error(
			err.Error(),
		))
	}

	// fire the event trigger
	if err := htmx.Trigger(ctx, "on-change-password-success"); err != nil {
		return utils.Render(ctx, 200, partials.Error(
			err.Error(),
		))
	}

	// return utils.Render(ctx, 200, views.PasswordChangedSuccess())
	return nil
}
