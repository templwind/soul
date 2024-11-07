package session

import (
	"net/http"

	"{{ .serviceName }}/internal/config"
	
	"github.com/labstack/echo/v4"
)

func SetCookie(cfg *config.Config, c echo.Context, token string, cookieName string) {
	c.SetCookie(&http.Cookie{
		Name:     cookieName,
		Value:    token,
		Path:     "/",
		Secure:   c.Request().URL.Scheme == "https",
		HttpOnly: true,
		MaxAge:   int(cfg.Auth.AccessExpire),
	})
}

func GetCookie(c echo.Context, cookieName string) string {
	cookie, err := c.Cookie(cookieName)
	if err != nil {
		return ""
	}
	return cookie.Value
}

func ClearCookies(c echo.Context, cookieNames ...string) {
	for _, cookieName := range cookieNames {
		c.SetCookie(&http.Cookie{
			Name:     cookieName,
			Value:    "",
			Path:     "/",
			Secure:   true,
			HttpOnly: true,
			MaxAge:   -1,
		})
	}
}
