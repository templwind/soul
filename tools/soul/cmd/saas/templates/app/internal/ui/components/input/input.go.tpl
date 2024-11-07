package input

import (
	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	Type        string
	Name        string
	Placeholder string
	Required    bool
	Class       string
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		Type:        "text",
		Name:        "input",
		Placeholder: "Enter value",
		Required:    false,
		Class:       "input input-bordered w-full",
	}
}

func WithType(inputType string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Type = inputType
	}
}

func WithName(name string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Name = name
	}
}

func WithPlaceholder(placeholder string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Placeholder = placeholder
	}
}

func WithRequired(required bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Required = required
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Class = class
	}
}
