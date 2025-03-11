package header

import (
	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	H1 string
	H2 string
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
	return &Props{}
}

func WithH1(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.H1 = v
	}
}

func WithH2(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.H2 = v
	}
}
