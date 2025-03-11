package setting

import (
	"{{ .serviceName }}/internal/settings"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	Setting settings.MergedSetting
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given opt
func NewWithProps(opt *Props) templ.Component {
	return soul.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given opt
func WithProps(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithSetting(setting settings.MergedSetting) soul.OptFunc[Props] {
	return func(p *Props) {
		p.Setting = setting
	}
}
