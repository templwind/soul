package login

import (
	"{{ .ModuleName }}/internal/middleware"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/utils"
	"{{ .ModuleName }}/internal/ui/components/apperror"

	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind/htmx"
)

func (c *Controller) HandlePost(e echo.Context) error {
	// bind the form
	err := e.Bind(c.form)
	if err != nil {
		return utils.Render(e, 200, apperror.New(
			"Invalid form data",
		))
	}

	// validate the form
	err = c.form.Validate()
	if err != nil {
		return utils.Render(e, 200, apperror.New(
			err.Error(),
		))
	}

	// find the user by email
	user, err := models.UserByEmail(e.Request().Context(), c.svcCtx.SqlxDB, c.form.Email)
	if err != nil {
		return utils.Render(e, 200, apperror.New(
			"User not found",
		))
	}

	// authenicate the user
	if !user.ValidatePassword(c.form.Password) {
		return utils.Render(e, 200, apperror.New(
			"Invalid password",
		))
	}

	// set the authentication token
	err = middleware.SetAuthToken(e, c.svcCtx, user)
	if err != nil {
		return utils.Render(e, 200, apperror.New(
			err.Error(),
		))
	}

	// how many accounts are associated with this?
	accounts, err := models.UserAccountsByUserID(e.Request().Context(), c.svcCtx.SqlxDB, user.ID)
	if err != nil && err != models.ErrDoesNotExist {
		return utils.Render(e, 200, apperror.New(
			err.Error(),
		))
	}

	if len(accounts) == 1 {
		err = middleware.SetAccountToken(e, c.svcCtx, accounts[0])
		if err != nil {
			return utils.Render(e, 200, apperror.New(
				err.Error(),
			))
		}
	}

	// add a header for a HX-Redirect
	return htmx.Redirect(
		e.Response().Writer,
		e.Request(),
		"/app",
	)
}
