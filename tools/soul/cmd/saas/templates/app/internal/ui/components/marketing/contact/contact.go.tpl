package contact

import (
	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	Description   []string
	Address       string
	Address2      string
	City          string
	StateProvince string
	Country       string
	Email         string
	Phone         string
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

func WithDescription(v ...string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Description = v
	}
}

func WithAddress(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Address = v
	}
}

func WithAddress2(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Address2 = v
	}
}

func WithCity(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.City = v
	}
}

func WithStateProvince(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.StateProvince = v
	}
}

func WithCountry(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Country = v
	}
}

func WithEmail(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Email = v
	}
}

func WithPhone(v string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Phone = v
	}
}
