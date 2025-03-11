package checkbox

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Props struct {
	ID             string
	Name           string
	Label          string
	Checked        bool
	Required       bool
	Class          string
	LabelClass     string
	ContainerClass string
	Value          string
	UseFormControl bool
	LabelPosition  string // "left" or "right"
}

// New creates a new component
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the props for the component
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		ID:            util.ToCamel(fmt.Sprintf("checkbox-%s", xid.New().String())),
		LabelPosition: "right",
	}
}

func WithID(id string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithName(name string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Name = name
	}
}

func WithLabel(label string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Label = label
	}
}

func WithChecked(checked bool) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Checked = checked
	}
}

func WithRequired(required bool) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Required = required
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}

func WithLabelClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.LabelClass = class
	}
}

func WithContainerClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.ContainerClass = class
	}
}

func WithValue(value string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Value = value
	}
}

func WithUseFormControl(useFormControl bool) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.UseFormControl = useFormControl
	}
}

func WithLabelPosition(position string) templwind.OptFunc[Props] {
	return func(props *Props) {
		if position == "left" || position == "right" {
			props.LabelPosition = position
		}
	}
}
