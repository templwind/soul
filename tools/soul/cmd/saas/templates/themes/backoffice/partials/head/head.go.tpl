package head

import (
	"os"

	"github.com/a-h/templ"
	"github.com/templwind/templwind"
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
func New(props ...templwind.OptFunc[Props]) templ.Component {
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

func WithEnvironment(environment string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Environment = environment
	}
}

func WithIsHome(isHome bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.IsHome = isHome
	}
}

func WithTitle(title string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Title = title
	}
}

func WithSiteTitle(siteTitle string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.SiteTitle = siteTitle
	}
}

func WithCSS(cssPaths ...string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.CSS = cssPaths
	}
}

func WithJS(jsPaths ...string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.JS = jsPaths
	}
}
