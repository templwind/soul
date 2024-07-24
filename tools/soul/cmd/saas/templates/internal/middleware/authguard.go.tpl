package middleware

import (
	"{{ .serviceName }}/internal/session"
	"strings"

	"github.com/labstack/echo/v4"
)

type AuthGuardMiddleware struct {
}

func NewAuthGuardMiddleware() *AuthGuardMiddleware {
	return &AuthGuardMiddleware{}
}

func (m *AuthGuardMiddleware) Handle(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {

		// if we're on the logout page, remove the cookies
		if strings.Contains(c.Request().RequestURI, "/logout") {
			session.ClearCookies(c, "auth", "account")
			c.Redirect(302, "/")
			return next(c)
		}

		// redirect everything that isn't an auth request
		if strings.Contains(c.Request().RequestURI, "/auth") {
			return next(c)
		}

		if session.UserFromContext(c) != nil {
			// fmt.Println("user is authenticated")
			return next(c)
		}

		return c.Redirect(302, "/auth/login")
	}
}
