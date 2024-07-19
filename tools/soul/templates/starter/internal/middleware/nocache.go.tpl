package middleware

import "github.com/labstack/echo/v4"

// NoCache sets headers to disable caching
func NoCache(next echo.HandlerFunc) echo.HandlerFunc {
	return func(e echo.Context) error {
		e.Response().Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate")
		e.Response().Header().Set("Pragma", "no-cache")
		e.Response().Header().Set("Expires", "0")
		e.Response().Header().Set("Surrogate-Control", "no-store")
		return next(e)
	}
}
