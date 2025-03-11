package headline

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

// Props defines the options for the Alert component
type Props struct {
	ID         string
	Start      string
	Highlight  string
	End        string
	MaxWidth   string
	ShowAccent bool
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
		ID:         util.ToCamel(fmt.Sprintf("headline-%s", xid.New().String())),
		ShowAccent: true,
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithStart(start string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Start = start
	}
}

func WithHighlight(highlight string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Highlight = highlight
	}
}

func WithEnd(end string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.End = end
	}
}

func WithMaxWidth(maxWidth string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.MaxWidth = maxWidth
	}
}

func WithShowAccent(showAccent bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ShowAccent = showAccent
	}
}
