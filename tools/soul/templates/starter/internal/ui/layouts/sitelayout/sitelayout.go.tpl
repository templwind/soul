package sitelayout

import (
	"{{ .ModuleName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind"
)

// Props defines the options for the AppBar component
type Props struct {
	Echo      echo.Context
	Config    *config.Config
	PageTitle string
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given opt
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given opt
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		PageTitle: "{{ .ModuleName }} Site",
	}
}

func WithEcho(e echo.Context) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Echo = e
	}
}

func WithConfig(c *config.Config) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Config = c
	}
}

func WithTitle(title string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.PageTitle = title
	}
}
