package indicator

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/soul"
	"github.com/templwind/soul/util"
)

type Props struct {
	ID          string
	CurrentStep int
	TotalSteps  int
	Class       string
}

// New creates a new component
func New(props ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new component with the given props
func NewWithProps(props *Props) templ.Component {
	return soul.NewWithProps(tpl, props)
}

// WithProps builds the props for the component
func WithProps(props ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, props...)
}

func defaultProps() *Props {
	return &Props{
		ID:          util.ToCamel(fmt.Sprintf("indicator-%s", xid.New().String())),
		CurrentStep: 1,
		TotalSteps:  4,
	}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithCurrentStep(step int) soul.OptFunc[Props] {
	return func(props *Props) {
		props.CurrentStep = step
	}
}

func WithTotalSteps(steps int) soul.OptFunc[Props] {
	return func(props *Props) {
		props.TotalSteps = steps
	}
}

func WithClass(class string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}
