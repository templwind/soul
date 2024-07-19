package utils

import (
	"context"
	"net/http"

	"github.com/a-h/templ"
	"github.com/labstack/echo/v4"
)

func Render(e echo.Context, status int, t templ.Component) error {
	e.Response().Writer.WriteHeader(status)

	err := t.Render(context.Background(), e.Response().Writer)
	if err != nil {
		return e.String(http.StatusInternalServerError, "failed to render response template")
	}

	return nil
}
