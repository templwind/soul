package dropdown

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Link struct {
	Icon  string
	Title string
	Link  string
	Click string
}

type Props struct {
	ID    string
	Links []Link
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithOpt creates a new component with the given prop
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the props with the given prop
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		ID: util.ToCamel(fmt.Sprintf("dropdown-%s", xid.New().String())),
	}
}

func WithLinks(items []Link) templwind.OptFunc[Props] {
	return func(o *Props) {
		o.Links = items
	}
}
