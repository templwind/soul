package header

import (
	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/session"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	ID              string
	Config          config.Config
	Menus           config.Menus
	HomeURL         string
	BrandName       string
	BrandLogo       string
	BrandLink       string
	LoginURL        string
	LoginTitle      string
	CallOut         templ.Component
	CallOutCss      string
	ShowLogin       bool
	AccountName     string
	Username        string
	FirstName       string
	Email           string
	SubscriptionCtx *session.SubscriptionCtx
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
		HomeURL:   "/",
		ShowLogin: true,
	}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithHomeURL(url string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.HomeURL = url
	}
}

func WithMenus(menus config.Menus) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Menus = menus
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

func WithLoginURL(url string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.LoginURL = url
	}
}

func WithLoginTitle(title string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.LoginTitle = title
	}
}

func WithConfig(config *config.Config) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Config = *config
	}
}

func WithCallOut(callOut templ.Component) soul.OptFunc[Props] {
	return func(o *Props) {
		o.CallOut = callOut
	}
}

func WithCallOutCss(color string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.CallOutCss = color
	}
}

func WithShowLogin(show bool) soul.OptFunc[Props] {
	return func(o *Props) {
		o.ShowLogin = show
	}
}

func WithAccountName(accountName string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.AccountName = accountName
	}
}

func WithUsername(username string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Username = username
	}
}

func WithFirstName(firstName string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.FirstName = firstName
	}
}

func WithEmail(email string) soul.OptFunc[Props] {
	return func(o *Props) {
		o.Email = email
	}
}

func WithSubscriptionCtx(subscriptionCtx *session.SubscriptionCtx) soul.OptFunc[Props] {
	return func(o *Props) {
		o.SubscriptionCtx = subscriptionCtx
	}
}
