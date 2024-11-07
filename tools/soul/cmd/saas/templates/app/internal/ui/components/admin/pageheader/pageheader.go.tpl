package pageheader

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/gosimple/slug"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Props struct {
	ID      string
	Title   string
	Href    templ.SafeURL
	Class   string
	Buttons []templ.Component
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the props for the component
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		ID: util.ToCamel(fmt.Sprintf("pageheader-%s", xid.New().String())),
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithTitle(title string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.ID = slug.Make(title)
		props.Title = title
	}
}

func WithHref(href templ.SafeURL) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Href = href
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}

func WithButtons(buttons ...templ.Component) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Buttons = buttons
	}
}
