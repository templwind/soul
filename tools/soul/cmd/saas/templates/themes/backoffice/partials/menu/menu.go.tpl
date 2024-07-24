package menu

import (
	"fmt"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/themes/backoffice"
	
	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/templwind"
)

type Props struct {
	backoffice.Props
	MenuID     string
	MenuKey    string
	Menus      config.Menus
	SearchForm templ.Component
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
	return &Props{
		MenuID: (xid.New()).String(),
		Props: backoffice.Props{HtmxTrigger: func(link string, totalSubItems int) string {
			return fmt.Sprintf("activeUrl = '%s'; drawerIsOpen = activeUrl.includes('%s') && %d > 0; $store.drawer.update(activeUrl, drawerIsOpen);", link, link, totalSubItems)
		}},
	}
}

func WithMenuID(menuID string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.MenuID = menuID
	}
}

func WithMenus(menus config.Menus) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
	}
}

func WithMenuKey(menuKey string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.MenuKey = menuKey
	}
}

func WithHtmxTrigger(htmxTrigger func(link string, totalSubItems int) string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HtmxTrigger = htmxTrigger
	}
}

func WithSearchForm(searchForm templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.SearchForm = searchForm
	}
}

func WithConfig(config *config.Config) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Config = *config
	}
}
