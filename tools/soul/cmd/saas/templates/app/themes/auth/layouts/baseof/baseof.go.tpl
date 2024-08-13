package baseof

import (
	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Props struct {
	Menus    config.Menus
	LangCode string
	LTRDir   string
	Head     templ.Component
	Header   templ.Component
	Content  templ.Component
	Footer   templ.Component
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given prosp
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the prospions with the given prosp
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		LangCode: "en",
		LTRDir:   "ltr",
	}
}

func WithLangCode(langCode string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.LangCode = langCode
	}
}

func WithLTRDir(ltrDir string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.LTRDir = ltrDir
	}
}

func WithHead(head templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Head = head
	}
}

func WithHeader(header templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Header = header
	}
}

func WithContent(content templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Content = content
	}
}

func WithFooter(footer templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Footer = footer
	}
}

func WithMenus(menus config.Menus) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
	}
}
