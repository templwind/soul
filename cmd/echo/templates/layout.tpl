package {{.PkgName}}

import (
	{{.Imports}}
)

// Props defines the options for the AppBar component
type Props struct {
	Request   *http.Request
	Config    *config.Config
	PageTitle string
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, layout, opts...)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(layout, opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		PageTitle: "SaaS Starter",
	}
}

func WithRequest(r *http.Request) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Request = r
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
