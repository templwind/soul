package middleware

import (
	{{.imports}}
)

type {{.name}} struct {
}

func New{{.name}}() *{{.name}} {
	return &{{.name}}{}
}

func (m *{{.name}})Handle(next echo.HandlerFunc) echo.HandlerFunc {
	{{- if .isNoCache }}
	return func(c echo.Context) error {
		c.Response().Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate")
		c.Response().Header().Set("Pragma", "no-cache")
		c.Response().Header().Set("Expires", "0")
		c.Response().Header().Set("Surrogate-Control", "no-store")
		return next(c)
	}
	{{else}}
	return func(c echo.Context) error {
		// TODO generate middleware implement function, delete after code implementation

		// Passthrough to next handler if need
		return next(c)
	}
	{{end -}}
}
