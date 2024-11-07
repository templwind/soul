package apprail

import (
	"{{ .serviceName }}/internal/ui/components/link"

	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

// Props defines the props for the AppRail component
type Props struct {
	Background  string
	Border      string
	Width       string
	Height      string
	Gap         string
	Hover       string
	Active      string
	Spacing     string
	AspectRatio string
	Lead        templ.Component
	Trail       templ.Component
	MenuItems   []*link.Props
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given prop
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the props with the given prop
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

// DefaultProps provides the default props for the AppRail component
func defaultProps() *Props {
	return &Props{
		Background:  "bg-surface-100-800-token",
		Border:      "",
		Width:       "w-20",
		Height:      "h-full",
		Gap:         "gap-0",
		Hover:       "bg-primary-hover-token",
		Active:      "bg-primary-active-token",
		Spacing:     "space-y-1",
		AspectRatio: "aspect-square",
		Lead:        nil,
		Trail:       nil,
		MenuItems:   make([]*link.Props, 0),
	}
}

func WithBackground(background string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Background = background
	}
}

func WithBorder(border string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Border = border
	}
}

func WithWidth(width string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Width = width
	}
}

func WithHeight(height string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Height = height
	}
}

func WithGap(gap string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Gap = gap
	}
}

func WithHover(hover string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Hover = hover
	}
}

func WithActive(active string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Active = active
	}
}

func WithSpacing(spacing string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Spacing = spacing
	}
}

func WithAspectRatio(aspectRatio string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.AspectRatio = aspectRatio
	}
}

func WithLead(lead templ.Component) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Lead = lead
	}
}

func WithMenuItems(menuItems ...*link.Props) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.MenuItems = append(props.MenuItems, menuItems...)
	}
}
