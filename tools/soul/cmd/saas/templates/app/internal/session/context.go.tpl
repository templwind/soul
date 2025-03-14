package session

import (
	"{{ .serviceName }}/internal/models"

	"github.com/labstack/echo/v4"
)

const (
	ContextAccountKey      string = "accountCtx"
	ContextUserKey         string = "userCtx"
	ContextSubscriptionKey string = "subscriptionCtx"
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

type SubscriptionCtx struct {
	// Subscription *models.Subscription
	// Product      *models.Product
}

func SubscriptionFromContext(c echo.Context) *SubscriptionCtx {
	if c.Get(ContextSubscriptionKey) == nil {
		return nil
	}
	return c.Get(ContextSubscriptionKey).(*SubscriptionCtx)
}
