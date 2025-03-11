package baseof

import (
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/themes/backoffice"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	backoffice.Props
	LangCode  string
	LTRDir    string
	Head      templ.Component
	Header    templ.Component
	RailMenu  templ.Component
	Content   templ.Component
	Footer    templ.Component
	BodyClass string
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
		Props: backoffice.Props{
			HxSSE: &struct {
				URL string
			}{
				URL: "/{{.serviceName}}/sse",
			},
			XData: `{ 
				activeUrl: window.location.pathname, 
				drawerIsOpen: false, 
				updateDrawerState() { 
					this.drawerIsOpen = $store.drawer.pages[this.activeUrl] ?? true; 
				} 
			}`,
			XInit: `
				$store.drawer = {
					pages: {},
					init() {
						this.pages = JSON.parse(localStorage.getItem('drawerStates') || '{}');
					},
					save() {
						localStorage.setItem('drawerStates', JSON.stringify(this.pages));
					},
					update(url, state) {
						this.pages[url] = state;
						this.save();
					}
				};
				$store.drawer.init();
				updateDrawerState();
				window.addEventListener('popstate', () => {
					activeUrl = window.location.pathname;
					updateDrawerState();
				});
			`,
		},
		BodyClass: "h-full antialiased light",
		LangCode:  "en",
		LTRDir:    "ltr",
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

func WithHtmxTrigger(htmxTrigger func(link string, totalSubItems int) string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.HtmxTrigger = htmxTrigger
	}
}

func WithHxSSE(url string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.HxSSE = &struct {
			URL string
		}{
			URL: url,
		}
	}
}

func WithXData(xData string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.XData = xData
	}
}

func WithXInit(xInit string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.XInit = xInit
	}
}

func WithBodyClass(bodyClass string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.BodyClass = bodyClass
	}
}

func WithRailMenu(railMenu templ.Component) soul.OptFunc[Props] {
	return func(p *Props) {
		p.RailMenu = railMenu
	}
}

func WithMenus(menus config.Menus) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
	}
}
