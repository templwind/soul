package middleware

import (
	"fmt"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/security"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

type UserGuardMiddleware struct {
	cfg *config.Config
	db  models.DB
}

func NewUserGuardMiddleware(cfg *config.Config, db models.DB) *UserGuardMiddleware {
	return &UserGuardMiddleware{
		cfg: cfg,
		db:  db,
	}
}

func (m *UserGuardMiddleware) Handle(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		tokenCookie, err := c.Request().Cookie(m.cfg.Auth.UserCookieName)
		if err != nil {
			// fmt.Println("tokenCookie:", err)
			return next(c)
		}

		token := tokenCookie.Value

		unverifiedClaims, err := security.ParseUnverifiedJWT(token)
		if err != nil {
			// fmt.Println("ParseUnverifiedJWT:", err)
			return next(c)
		}

		id, ok := unverifiedClaims["id"].(string)
		if !ok {
			fmt.Println("Error: 'id' claim is not a string")
			return next(c)
		}

		// find user by id
		user, err := models.UserByID(c.Request().Context(), m.db, uuid.MustParse(id))
		if err != nil {
			// fmt.Println(err)
			return next(c)
		}

		// verify token signature
		if _, err := security.ParseJWT(token, m.cfg.Auth.AccessSecret); err != nil {
			// fmt.Println(err)
			return next(c)
		}
		c.Set(ContextUserKey, user)

		// fmt.Println("auth middleware: token verified")
		return next(c)
	}
}
