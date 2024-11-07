package card

import (
	"{{ .serviceName }}/internal/ui/components/indicator"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	ID             string
	Class          string
	Title          string
	TitleSubscript string
	TitleClass     string
	SubTitle       string
	Lead           string
	HeadIndicator  *indicator.Props
	Components     []templ.Component
	Buttons        templ.Component
	TitleButtons   []templ.Component
}

// New creates a new component
func New(props ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return soul.NewWithProps(tpl, props)
}

// WithProps builds the propsions with the given props
func WithProps(props ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		// Class: "bg-white border border-slate-200 rounded-lg shadow dark:bg-slate-800 dark:border-slate-700",
		Class: "card bg-base-100 shadow-xl",
	}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithClass(class string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}

func WithTitle(title string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Title = title
	}
}

func WithTitleClass(titleClass string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.TitleClass = titleClass
	}
}

func WithTitleSubscript(titleSubscript string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.TitleSubscript = titleSubscript
	}
}

func WithSubTitle(subTitle string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.SubTitle = subTitle
	}
}

func WithLead(lead string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Lead = lead
	}
}

func WithHeadIndicator(headIndicator *indicator.Props) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HeadIndicator = headIndicator
	}
}

func WithComponents(components ...templ.Component) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Components = components
	}
}

func WithButtons(buttons templ.Component) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Buttons = buttons
	}
}

func WithTitleButtons(titleButtons ...templ.Component) soul.OptFunc[Props] {
	return func(props *Props) {
		props.TitleButtons = titleButtons
	}
}
