package baseof

import (
	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	Config            *config.Config
	Theme             string
	Menus             config.Menus
	LangCode          string
	LTRDir            string
	HomeURL           string
	BrandName         string
	BrandLogo         string
	BrandLink         string
	Head              templ.Component
	Header            templ.Component
	Content           templ.Component
	Footer            templ.Component
	Disclaimer        templ.Component
	SidebarMenu       templ.Component
	SidebarFooterMenu templ.Component
	SidebarSocialMenu templ.Component
	ShowSidebar       bool
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
		LangCode:    "en",
		LTRDir:      "ltr",
		Theme:       "light",
		ShowSidebar: true,
	}
}

func WithConfig(cfg *config.Config) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Config = cfg
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

func WithoutHeader() soul.OptFunc[Props] {
	return func(p *Props) {
		p.Header = nil
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

func WithoutFooter() soul.OptFunc[Props] {
	return func(p *Props) {
		p.Footer = nil
	}
}

func WithMenus(menus config.Menus) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
	}
}

func WithDisclaimer(disclaimer templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Disclaimer = disclaimer
	}
}

func WithSidebarMenu(SidebarMenu templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.SidebarMenu = SidebarMenu
	}
}

func WithSidebarFooterMenu(SidebarFooterMenu templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.SidebarFooterMenu = SidebarFooterMenu
	}
}

func WithSidebarSocialMenu(SidebarSocialMenu templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.SidebarSocialMenu = SidebarSocialMenu
	}
}

func WithHomeURL(url string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.HomeURL = url
	}
}

func WithBrandName(name string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.BrandName = name
	}
}

func WithBrandLogo(logo string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.BrandLogo = logo
	}
}

func WithBrandURL(link string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.BrandLink = link
	}
}

func WithShowSidebar(showSidebar bool) soul.OptFunc[Props] {
	return func(o *Props) {
		o.ShowSidebar = showSidebar
	}
}
