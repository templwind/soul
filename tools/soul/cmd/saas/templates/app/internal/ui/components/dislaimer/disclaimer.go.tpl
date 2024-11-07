package disclaimer

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

// Props defines the options for the Disclaimer component
type Props struct {
	ID         string
	Disclaimer templ.Component
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given opt
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given opt
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		ID: util.ToCamel(fmt.Sprintf("disclaimer-%s", xid.New().String())),
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithDisclaimer(disclaimer string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Disclaimer = templwind.Markdown(disclaimer)
	}
}
