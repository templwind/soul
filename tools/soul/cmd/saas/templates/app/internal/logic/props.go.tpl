package {{.pkgName}}

import (
	{{.imports}}
)

// Props defines the options for the AppBar component
type Props struct {
	Request   *http.Request
	Config    *config.Config
	PageTitle string
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, {{.templName}}, opts...)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	return soul.NewWithProps({{.templName}}, opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithRequest(r *http.Request) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Request = r
	}
}

func WithConfig(c *config.Config) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Config = c
	}
}

func WithTitle(title string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.PageTitle = title
	}
}
