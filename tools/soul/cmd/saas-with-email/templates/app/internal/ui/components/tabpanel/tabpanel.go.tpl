package tabpanel

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Tab struct {
	ID          string
	Label       string
	Description string
	ImageURL    string
	ImageAlt    string
	Component   templ.Component
}

type Props struct {
	ID   string
	Tabs []Tab
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
		ID: util.ToCamel(fmt.Sprintf("tabpanel-%s", xid.New().String())),
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithTabs(tabs ...Tab) templwind.OptFunc[Props] {
	return func(p *Props) {
		for i := range tabs {
			if tabs[i].ID == "" {
				tabs[i].ID = util.ToCamel(fmt.Sprintf("tab-%s", xid.New().String()))
			}
		}
		p.Tabs = tabs
	}
}
