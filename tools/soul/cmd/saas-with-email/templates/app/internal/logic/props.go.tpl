package {{.pkgName}}

import (
	{{.imports}}
)

// Props defines the options for the AppBar component
type Props struct {
	Component func(*Props) templ.Component
	Request   *http.Request
	Config    *config.Config
	PageTitle string
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	// Construct the Props with the given options
	props := soul.WithProps(defaultProps, opts...)

	// Enforce that a Component function is provided
	if props.Component == nil {
		panic("no Component function provided to New function")
	}

	// Use the Component function to generate the templ.Component
	return props.Component(props)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	// Use the Component provided in the Props
	if opt.Component == nil {
		panic("no Component provided to NewWithProps function")
	}
	return opt.Component(opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, opts...)
}

// defaultProps returns the default props
func defaultProps() *Props {
	return &Props{}
}

// Option function to set the Component
func WithComponent(c func(*Props) templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Component = c
	}
}

// Option function to set the Request
func WithRequest(r *http.Request) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Request = r
	}
}

// Option function to set the PageTitle
func WithPageTitle(t string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.PageTitle = t
	}
}

// Option function to set the Config
func WithConfig(c *config.Config) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Config = c
	}
}