package head

import (
	"os"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type ProdFile struct {
	MinifiedPermalink string
	Integrity         string
}

type Props struct {
	Environment string
	IsHome      bool
	Title       string
	SiteTitle   string
	CSS         []string
	JS          []string
	CssCache    map[string]ProdFile
	JSCache     map[string]ProdFile
}

// New creates a new component
func New(props ...soul.OptFunc[Props]) templ.Component {
	p := WithProps(props...)
	if p.Environment == "production" {
		for _, cssPath := range p.CSS {
			cache, err := SetProdCache(cssPath)
			if err != nil {
				panic(err)
			}

			p.CssCache = cache
		}
		for _, jsPath := range p.JS {
			cache, err := SetProdCache(jsPath)
			if err != nil {
				panic(err)
			}
			p.JSCache = cache
		}
	}
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
	environment := os.Getenv("ENVIRONMENT")
	if environment == "" {
		environment = "development"
	} else {
		environment = "production"
	}
	return &Props{
		Environment: environment,
	}
}

func WithEnvironment(environment string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Environment = environment
	}
}

func WithIsHome(isHome bool) soul.OptFunc[Props] {
	return func(p *Props) {
		p.IsHome = isHome
	}
}

func WithTitle(title string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Title = title
	}
}

func WithSiteTitle(siteTitle string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.SiteTitle = siteTitle
	}
}

func WithCSS(cssPaths ...string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.CSS = cssPaths
	}
}

func WithJS(jsPaths ...string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.JS = jsPaths
	}
}
