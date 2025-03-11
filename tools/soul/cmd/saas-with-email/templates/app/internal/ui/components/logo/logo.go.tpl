package logo

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

var wordRegex = regexp.MustCompile("([a-z0-9])([A-Z])")

type Size string

const (
	SizeSmall  Size = "text-2xl md:text-3xl lg:text-4xl font-black"
	SizeMedium Size = "text-3xl md:text-4xl lg:text-5xl font-black"
	SizeLarge  Size = "text-4xl md:text-5xl lg:text-6xl font-black"
)

// Props defines the options for the Disclaimer component
type Props struct {
	ID        string
	BrandName string
	Words     []string
	Colors    []string
	Size      Size
}

// String func
func (s Size) String() string {
	return string(s)
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
		ID:   util.ToCamel(fmt.Sprintf("disclaimer-%s", xid.New().String())),
		Size: SizeLarge,
		Colors: []string{
			"text-accent",
			"text-secondary",
			"text-accent",
		},
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

func WithBrandName(brandName string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.BrandName = brandName
	}
}

func WithFancyBrandName(brandName string) templwind.OptFunc[Props] {
	return func(p *Props) {
		// split the brand name into words
		// camel case to words
		processedName := wordRegex.ReplaceAllString(brandName, "$1 $2")
		p.Words = strings.Fields(processedName)
	}
}

func WithColors(colors ...string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Colors = colors
	}
}

func WithSize(size Size) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Size = size
	}
}
