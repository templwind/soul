package footer

import (
	"strconv"
	"strings"
	"time"

	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	Config config.Config
	Menus  config.Menus
	Year   string
}

func (p *Props) GetChildrenByURL(baseURL string) []config.MenuEntry {
	var children []config.MenuEntry
	if menu, ok := p.Menus["footer"]; ok {
		for _, item := range menu {
			if item.Children != nil && strings.Contains(item.URL, baseURL) {
				children = append(children, item.Children...)
			}
		}
	}
	return children
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

func WithYear(year string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Year = year
	}
}
