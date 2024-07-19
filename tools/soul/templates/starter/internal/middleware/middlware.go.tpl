package middleware

import (
	"net/http"

    "{{ .ModuleName }}/internal/models"

	"github.com/labstack/echo/v4"
)

const (
	ContextAccountKey string = "accountCtx"
	ContextUserKey    string = "userCtx"
)

func AccountFromContext(e echo.Context) *models.Account {
	// fmt.Println("AccountFromContext", e.Get(ContextAccountKey))

	if e.Get(ContextAccountKey) == nil {
		return nil
	}
	return e.Get(ContextAccountKey).(*models.Account)
}

func UserFromContext(e echo.Context) *models.User {
	if e.Get(ContextUserKey) == nil {
		return nil
	}
	return e.Get(ContextUserKey).(*models.User)
}

func ClearCookies(e echo.Context, cookieNames ...string) {
	for _, cookieName := range cookieNames {
		e.SetCookie(&http.Cookie{
			Name:     cookieName,
			Value:    "",
			Path:     "/",
			Secure:   true,
			HttpOnly: true,
			MaxAge:   -1,
		})
	}
}
