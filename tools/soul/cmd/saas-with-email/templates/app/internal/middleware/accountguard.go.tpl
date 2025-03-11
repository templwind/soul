package middleware

import (
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/security"
	"fmt"

	"github.com/labstack/echo/v4"
)

type AccountGuardMiddleware struct {
	cfg *config.Config
	db  models.DB
}

func NewAccountGuardMiddleware(cfg *config.Config, db models.DB) *AccountGuardMiddleware {
	return &AccountGuardMiddleware{
		cfg: cfg,
		db:  db,
	}
}

func (m *AccountGuardMiddleware) Handle(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		tokenCookie, err := c.Request().Cookie(m.cfg.Auth.AccountCookieName)
		if err != nil {
			// fmt.Println("tokenCookie:", err)
			return next(c)
		}

		token := tokenCookie.Value

		unverifiedClaims, err := security.ParseUnverifiedJWT(token)
		if err != nil {
			fmt.Println("ParseUnverifiedJWT:", err)
			return next(c)
		}

		// check required claims
		id, ok := unverifiedClaims["id"].(float64)
		if !ok {
			fmt.Println("Error: 'id' claim is not a float64")
			return next(c)
		}

		// find account by id
		account, err := models.AccountByID(c.Request().Context(), m.db, int64(id))
		if err != nil {
			// fmt.Println(err)
			return next(c)
		}

		// verify token signature
		if _, err := security.ParseJWT(token, m.cfg.Auth.AccessSecret); err != nil {
			// fmt.Println(err)
			return next(c)
		}
		c.Set(ContextAccountKey, account)

		// fmt.Println("auth middleware: token verified")
		return next(c)
	}
}
