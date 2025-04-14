package notfound

import (
	"net/http"
	"strings"

	pageLayout "backend/internal/logic/notfound"
	"backend/internal/svc"
	error4x "backend/themes/templwind/error4x"
	baseof "backend/themes/templwind/layouts/baseof"

	"github.com/labstack/echo/v4"
	"github.com/templwind/soul"
	"github.com/templwind/soul/htmx"
)

// NotFoundHandler handles 404 errors and renders the appropriate response.
func NotFoundHandler(svcCtx *svc.ServiceContext) echo.HandlerFunc {
	return func(c echo.Context) error {
		if strings.Contains(c.Request().Header.Get("Accept"), "application/json") {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Resource not found"})
		}

		// intercept htmx requests and just return the error
		if htmx.IsHtmxRequest(c.Request()) {
			return soul.Render(c, http.StatusOK,
				error4x.New(
					error4x.WithErrors("Page Not Found"),
				),
			)
		}

		// Render HTML 404 page
		return soul.Render(c, http.StatusNotFound,
			baseof.New(
				pageLayout.Error4xLayout(c, svcCtx)...,
			),
		)
	}
}
