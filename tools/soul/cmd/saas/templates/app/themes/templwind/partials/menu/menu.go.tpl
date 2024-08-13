package menu

import (
	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	MenuID      string
	MenuEntries []config.MenuEntry
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the options with the given props
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithMenuID(menuID string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.MenuID = menuID
	}
}

func WithMenuEntries(menuEntries []config.MenuEntry) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.MenuEntries = menuEntries
	}
}
