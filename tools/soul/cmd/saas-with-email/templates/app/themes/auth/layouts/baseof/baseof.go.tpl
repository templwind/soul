package baseof

import (
	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	Config   *config.Config
	Theme    string
	Menus    config.Menus
	LangCode string
	LTRDir   string
	Head     templ.Component
	Header   templ.Component
	Content  templ.Component
	Footer   templ.Component
}

// New creates a new component
func New(props ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given prosp
func NewWithProps(props *Props) templ.Component {
	return soul.NewWithProps(tpl, props)
}

// WithProps builds the prospions with the given prosp
func WithProps(props ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		Theme:    "light",
		LangCode: "en",
		LTRDir:   "ltr",
	}
}

func WithConfig(config *config.Config) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Config = config
	}
}

func WithTheme(theme string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Theme = theme
	}
}

func WithLangCode(langCode string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.LangCode = langCode
	}
}

func WithLTRDir(ltrDir string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.LTRDir = ltrDir
	}
}

func WithHead(head templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Head = head
	}
}

func WithHeader(header templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Header = header
	}
}

func WithContent(content templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Content = content
	}
}

func WithFooter(footer templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Footer = footer
	}
}

func WithMenus(menus config.Menus) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
	}
}
