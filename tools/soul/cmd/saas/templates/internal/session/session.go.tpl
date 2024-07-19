package session

import (
	"{{ .serviceName }}/internal/models"

	"github.com/labstack/echo/v4"
)

const (
	ContextAccountKey string = "accountCtx"
	ContextUserKey    string = "userCtx"
)

func AccountFromContext(c echo.Context) *models.Account {
	if c.Get(ContextAccountKey) == nil {
		return nil
	}
	return c.Get(ContextAccountKey).(*models.Account)
}

func UserFromContext(c echo.Context) *models.User {
	if c.Get(ContextUserKey) == nil {
		return nil
	}
	return c.Get(ContextUserKey).(*models.User)
}
