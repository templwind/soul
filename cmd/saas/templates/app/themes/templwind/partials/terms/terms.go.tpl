package terms

import (
	"github.com/a-h/templ"
	"github.com/templwind/templwind"
)

type Term struct {
	RelPermalink string
	LinkTitle    string
	Parent       *Term
}

type Page struct {
	GetTerms func(taxonomy string) []Term
}

type Props struct {
	Label string
	Terms []Term
}

func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, opts...)
}

func defaultProps() *Props {
	return &Props{
		Terms: []Term{},
	}
}

func WithLabel(label string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Label = label
	}
}

func WithTerms(terms []Term) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Terms = terms
	}
}
