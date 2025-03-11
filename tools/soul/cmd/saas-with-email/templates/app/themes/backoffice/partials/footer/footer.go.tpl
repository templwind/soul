package footer

import (
	"strconv"
	"time"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/themes/backoffice"
	
	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	backoffice.Props
	Year        string
	MenuEntries []config.MenuEntry
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
	return &Props{
		Year: strconv.Itoa(time.Now().Year()),
		Props: backoffice.Props{
			HtmxTrigger: func(link string, totalSubItems int) string {
				return ""
			},
		},
	}
}

func WithYear(year string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Year = year
	}
}

func WithHtmxTrigger(htmxTrigger func(link string, totalSubItems int) string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.HtmxTrigger = htmxTrigger
	}
}

func WithMenuEntries(menuEntries []config.MenuEntry) soul.OptFunc[Props] {
	return func(p *Props) {
		p.MenuEntries = menuEntries
	}
}

func WithConfig(c *config.Config) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Config = *c
	}
}

func WithMenus(m config.Menus) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = m
	}
}

func totalItems(m []config.MenuEntry) int {
	return len(m)
}
