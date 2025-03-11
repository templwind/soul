package terms

import (
	"github.com/a-h/templ"
	"github.com/templwind/soul"
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

func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, opts...)
}

func defaultProps() *Props {
	return &Props{
		Terms: []Term{},
	}
}

func WithLabel(label string) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Label = label
	}
}

func WithTerms(terms []Term) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Terms = terms
	}
}
