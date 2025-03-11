package middleware

import (
	"strings"

	"{{ .serviceName }}/internal/session"

	"github.com/labstack/echo/v4"
)

type ChooseAccountGuardMiddleware struct {
}

func NewChooseAccountGuardMiddleware() *ChooseAccountGuardMiddleware {
	return &ChooseAccountGuardMiddleware{}
}

func (m *ChooseAccountGuardMiddleware) Handle(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {

		// make sure we're not on choose-account page
		if strings.Contains(c.Request().RequestURI, "/app/settings/choose-account") {
			// fmt.Println("choose-account page")
			return next(c)
		}

		if session.AccountFromContext(c) != nil {
			// fmt.Println("has valid account")
			return next(c)
		}

		return c.Redirect(302, "/app/settings/choose-account")
	}
}
