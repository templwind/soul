package error500

import (
	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	Errors []string
}

// New creates a new component
func New(props ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return soul.NewWithProps(tpl, props)
}

// WithProps builds the options with the given props
func WithProps(props ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithErrors(errors ...string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Errors = errors
	}
}
