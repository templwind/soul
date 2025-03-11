package selectbox

import (
	"fmt"
	"sort"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul/util"
	"github.com/templwind/templwind"
)

type Option struct {
	Value string
	Text  string
}

type Props struct {
	ID                string
	Name              string
	Label             string
	InstructionOption string
	Options           []Option
	OptionMap         map[string]string
	Selected          string
	Required          bool
	Class             string
	LabelClass        string
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
		ID:      util.ToCamel(fmt.Sprintf("select-%s", xid.New().String())),
		Options: []Option{},
	}
}

func WithInstructionOption(instructionOption string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.InstructionOption = instructionOption
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

func WithOptions(options ...Option) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Options = options
	}
}

func WithRequired(required bool) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Required = required
	}
}

func WithSelected(selected string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Selected = selected
	}
}

func WithClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}

func WithOptionMap(optionMap map[string]string) templwind.OptFunc[Props] {
	// Convert the map to a slice of selectbox.Option
	var opts []Option
	for k, v := range optionMap {
		opts = append(opts, Option{Value: k, Text: v})
	}

	// Sort the optionMap slice by the Text field
	sort.Slice(opts, func(i, j int) bool {
		return opts[i].Text < opts[j].Text
	})

	// Return a function that sets the sorted options into Props
	return func(p *Props) {
		p.Options = opts
	}
}

func WithLabelClass(class string) templwind.OptFunc[Props] {
	return func(props *Props) {
		props.LabelClass = class
	}
}
