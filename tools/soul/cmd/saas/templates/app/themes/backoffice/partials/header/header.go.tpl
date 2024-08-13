package header

import (
	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	ID         string
	Config     config.Config
	Menus      config.Menus
	MenuKey    string
	BrandName  string
	BrandLogo  string
	BrandLink  string
	LoginURL   string
	LoginTitle string
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
		MenuKey: "main",
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
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

func WithBrandName(name string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.BrandName = name
	}
}

func WithBrandLogo(logo string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.BrandLogo = logo
	}
}

func WithBrandURL(link string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.BrandLink = link
	}
}

func WithLoginURL(url string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.LoginURL = url
	}
}

func WithLoginTitle(title string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.LoginTitle = title
	}
}

func WithConfig(config *config.Config) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Config = *config
	}
}
