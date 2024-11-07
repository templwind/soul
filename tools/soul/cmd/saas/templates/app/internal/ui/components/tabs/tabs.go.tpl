package tabs

import (
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/config"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul"
	"github.com/templwind/soul/util"
)

type Tab struct {
	ID string
}

type Props struct {
	ID          string
	MenuEntries []config.MenuEntry
	Request     *http.Request
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given opt
func NewWithProps(opt *Props) templ.Component {
	return soul.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given opt
func WithProps(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		ID: util.ToCamel(fmt.Sprintf("tabpanel-%s", xid.New().String())),
	}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithMenuEntries(menuEntries []config.MenuEntry) soul.OptFunc[Props] {
	return func(p *Props) {
		p.MenuEntries = menuEntries
	}
}

func WithRequest(request *http.Request) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Request = request
	}
}
