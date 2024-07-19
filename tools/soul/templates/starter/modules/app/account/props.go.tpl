package account

import (
	"{{ .ModuleName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/labstack/echo/v4"
	"github.com/templwind/templwind"
)

type Props struct {
	Echo         echo.Context
	Config       *config.Config
	ID           string
	Account	     *models.Account
	PrimaryUser  *models.User
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the propsions with the given props
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithEcho(e echo.Context) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Echo = e
	}
}

func WithConfig(cfg *config.Config) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Config = cfg
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.ID = id
	}
}

func WithAccount(account *models.Account) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Account = account
	}
}

func WithPrimaryUser(primaryUser *models.User) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.PrimaryUser = primaryUser
	}
}