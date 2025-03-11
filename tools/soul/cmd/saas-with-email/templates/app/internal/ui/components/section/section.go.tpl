package section

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/templwind"
)

// Props defines the properties for the section component.
type Props struct {
	ID     string // Unique identifier for the section
	Shadow bool   // Whether the section should have a shadow
	Class  string // Custom css for the section
}

// New creates a new section component with optional properties.
// Example usage:
// section := section.New(
//
//	section.WithComponent(templ.Component),
//
// )
// This will create a success section with a close button and a custom message.
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new section component with the given properties.
// Example usage:
//
//	props := &section.Props{
//	    Component: templ.Component,
//	}
//
// section := section.NewWithProps(props)
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the properties with the given options.
// Example usage:
// props := section.WithProps(
//
//	section.WithComponent(templ.Component),
//
// )
// section := section.NewWithProps(props)
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

// defaultProps provides the default properties for the section component.
func defaultProps() *Props {
	return &Props{
		ID: fmt.Sprintf("section-%s", xid.New().String()),
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithShadow(shadow bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Shadow = shadow
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Class = class
	}
}
