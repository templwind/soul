package appheader

import (
	"fmt"

	"{{ .serviceName }}/internal/ui/components/link"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul"
	"github.com/templwind/soul/util"
)

type Props struct {
	ID           string
	HideOnMobile bool
	LinkProps    *link.Props
	Title        string
	Subtitle     string
	Buttons      []templ.Component
	IsSticky     bool
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given opt
func NewWithProps(opt *Props) templ.Component {
	return soul.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given opt
func WithProps(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		ID:           util.ToCamel(fmt.Sprintf("header-%s", xid.New().String())),
		HideOnMobile: false,
		Title:        "App Header",
	}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.ID = id
	}
}

func WithHideOnMobile(hide bool) soul.OptFunc[Props] {
	return func(o *Props) {
		o.HideOnMobile = hide
	}
}

func WithLinkProps(linkProps ...soul.OptFunc[link.Props]) soul.OptFunc[Props] {
	return func(o *Props) {
		o.LinkProps = link.WithProps(linkProps...)
	}
}

func WithTitle(title string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Title = title
	}
}

func WithSubtitle(subtitle string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Subtitle = subtitle
	}
}

func WithButtons(buttons ...templ.Component) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Buttons = buttons
	}
}

func WithIsSticky(isSticky bool) soul.OptFunc[Props] {
	return func(o *Props) {
		o.IsSticky = isSticky
	}
}
