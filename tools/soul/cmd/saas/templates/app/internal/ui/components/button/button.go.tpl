package button

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Props struct {
	ID       string
	Type     string
	Label    string
	Class    string
	OnClick  string
	HxGet    string
	HxPost   string
	HxPut    string
	HxDelete string
	HxTarget string
	HXSwap   string
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, buttonView, opts...)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(buttonView, opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{
		ID:    util.ToCamel(fmt.Sprintf("button-%s", xid.New().String())),
		Type:  "button",
		Label: "Submit",
		Class: "btn btn-primary w-full md:w-auto",
	}
}

func WithType(buttonType string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Type = buttonType
	}
}

func WithLabel(label string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Label = label
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Class = class
	}
}

func WithOnClick(onClick string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.OnClick = onClick
	}
}

func WithHxGet(hxGet string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HxGet = hxGet
	}
}

func WithHxPost(hxPost string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HxPost = hxPost
	}
}

func WithHxPut(hxPut string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HxPut = hxPut
	}
}

func WithHxDelete(hxDelete string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HxDelete = hxDelete
	}
}

func WithHxTarget(hxTarget string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HxTarget = hxTarget
	}
}

func WithHxSwap(hxSwap string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HXSwap = hxSwap
	}
}
