package middleware

import (
	"github.com/labstack/echo/v4"
)

type NoCacheMiddleware struct {
}

func NewNoCacheMiddleware() *NoCacheMiddleware {
	return &NoCacheMiddleware{}
}

func (m *NoCacheMiddleware) Handle(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate")
		c.Response().Header().Set("Pragma", "no-cache")
		c.Response().Header().Set("Expires", "0")
		c.Response().Header().Set("Surrogate-Control", "no-store")
		return next(c)
	}
}
