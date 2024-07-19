package register

import (
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/internal/utils"
	// "{{ .ModuleName }}/internal/ui/components/apperror"

	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind/htmx"
)

type Controller struct {
	svcCtx *svc.ServiceContext
	form   *RegisterForm
}

func NewController(svcCtx *svc.ServiceContext) *Controller {
	return &Controller{
		svcCtx: svcCtx,
		form:   new(RegisterForm),
	}
}

func (c *Controller) HandleGet(e echo.Context) error {
	return utils.Render(e, 200, New(
		WithConfig(c.svcCtx.Config),
		WithEcho(e),
		WithForm(c.form),
	))
}

func (c *Controller) HandlePost(e echo.Context) error {
	// // bind the form
	// err := e.Bind(c.form)
	// if err != nil {
	// 	return utils.Render(e, 200, partials.Error(
	// 		"Invalid form data",
	// 	))
	// }

	// // validate the form
	// err = c.form.Validate()
	// if err != nil {
	// 	return utils.Render(e, 200, partials.Error(
	// 		err.Error(),
	// 	))
	// }

	// // find the user by email
	// user, err := models.UserByEmail(e.Request().Context(), c.svcCtx.SqlxDB, c.form.Email)
	// if err != nil {
	// 	return utils.Render(e, 200, partials.Error(
	// 		"User not found",
	// 	))
	// }

	// // fmt.Printf("user: %v\n", user.PasswordHash)

	// // authenicate the user
	// if !user.ValidatePassword(c.form.Password) {
	// 	return utils.Render(e, 200, partials.Error(
	// 		"Invalid password",
	// 	))
	// }

	// // set the authentication token
	// err = middleware.SetAuthToken(e, c.svcCtx, user)
	// if err != nil {
	// 	return utils.Render(e, 200, partials.Error(err.Error()))
	// }

	// // how many accounts are associated with this?
	// accounts, err := models.UserAccountsByUserID(e.Request().Context(), c.svcCtx.SqlxDB, user.ID)
	// if err != nil && err != models.ErrDoesNotExist {
	// 	return utils.Render(e, 200, partials.Error(err.Error()))
	// }

	// if len(accounts) == 1 {
	// 	err = middleware.SetAccountToken(e, c.svcCtx, accounts[0])
	// 	if err != nil {
	// 		return utils.Render(e, 200, partials.Error(err.Error()))
	// 	}
	// }

	// add a header for a HX-Redirect
	return htmx.Redirect(
		e.Response().Writer,
		e.Request(),
		"/login",
	)
}