package toast

import (
	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

// Props defines the options for the AppBar component
type Props struct {
	ID      string
	Message string
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
		ID: "toast",
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithMessage(message string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Message = message
	}
}
