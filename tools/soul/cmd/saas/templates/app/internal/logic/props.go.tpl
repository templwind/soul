package {{.pkgName}}

import (
	{{.imports}}
)

// Props defines the options for the AppBar component
type {{.templName}}Props struct {
	Request   *http.Request
	Config    *config.Config
}

// New creates a new component
func (p *{{.templName}}Props) New(opts ...soul.OptFunc[{{.templName}}Props]) templ.Component {
	return soul.New(p.defaultProps, {{.templName}}View, opts...)
}

// NewWithProps creates a new component with the given options
func (p *{{.templName}}Props) NewWithProps(opt *{{.templName}}Props) templ.Component {
	return soul.NewWithProps({{.templName}}View, opt)
}

// WithProps builds the options with the given options
func (p *{{.templName}}Props) WithProps(opts ...soul.OptFunc[{{.templName}}Props]) *{{.templName}}Props {
	return soul.WithProps(p.defaultProps, opts...)
}

func (p *{{.templName}}Props) defaultProps() *{{.templName}}Props {
	return &{{.templName}}Props{}
}

func (p *{{.templName}}Props) WithRequest(r *http.Request) soul.OptFunc[{{.templName}}Props] {
	return func(p *{{.templName}}Props) {
		p.Request = r
	}
}

func (p *{{.templName}}Props) WithConfig(c *config.Config) soul.OptFunc[{{.templName}}Props] {
	return func(p *{{.templName}}Props) {
		p.Config = c
	}
}