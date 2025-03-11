package link

import (
	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

type Props struct {
	ID         string
	Title      string
	Href       string
	Subtitle   string
	Badge      templ.Component
	Icon       string
	EndIcon    string
	Class      string
	HXGet      string
	HXPost     string
	HXPut      string
	HXPatch    string
	HXDelete   string
	Target     string
	HXSwap     Swap
	HXTarget   string
	HXTrigger  []string
	HXPushURL  bool
	HXBoost    string
	XOnTrigger string
	Submenu    []*Props
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
	return &Props{}
}

func WithID(id string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.ID = id
	}
}

func WithTitle(title string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Title = title
	}
}

func WithSubtitle(subtitle string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Subtitle = subtitle
	}
}

func WithBadge(badge templ.Component) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Badge = badge
	}
}

func WithIcon(icon string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Icon = icon
	}
}

func WithEndIcon(endIcon string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.EndIcon = endIcon
	}
}

func WithClass(class string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Class = class
	}
}

func WithHXGet(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXGet = href
	}
}

func WithHXPost(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXPost = href
	}
}

func WithHXPut(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXPut = href
	}
}

func WithHXPatch(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXPatch = href
	}
}

func WithHXDelete(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXDelete = href
	}
}

func WithTarget(target string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Target = target
	}
}

type Swap string

func (s Swap) String() string {
	return string(s)
}

const (
	// the default, puts the content inside the target element
	InnerHTML Swap = "innerHTML"
	// replaces the entire target element with the returned content
	OuterHTML Swap = "outerHTML"
	// prepends the content before the first child inside the target
	AfterBegin Swap = "afterbegin"
	// prepends the content before the target in the target’s parent element
	BeforeBegin Swap = "beforebegin"
	// appends the content after the last child inside the target
	BeforeEnd Swap = "beforeend"
	// appends the content after the target in the target’s parent element
	AfterEnd Swap = "afterend"
	// deletes the target element regardless of the response
	Delete Swap = "delete"
	// does not append content from response (Out of Band Swaps and Response Headers will still be processed)
	None Swap = "none"
)

func WithHXSwap(hxSwap Swap) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXSwap = hxSwap
	}
}

func WithHXTarget(hxTarget string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXTarget = hxTarget
	}
}

func WithHXTrigger(hxTrigger []string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXTrigger = hxTrigger
	}
}

func WithHXPushURL(hxPushURL bool) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXPushURL = hxPushURL
	}
}

func WithXOnTrigger(xOnTrigger string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.XOnTrigger = xOnTrigger
	}
}

func WithSubmenu(linkProps ...*Props) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Submenu = append(props.Submenu, linkProps...)
	}
}

func WithHxBoost(hxBoost string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.HXBoost = hxBoost
	}
}

func WithHref(href string) soul.OptFunc[Props] {
	return func(props *Props) {
		props.Href = href
	}
}
