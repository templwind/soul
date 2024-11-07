package alert

import (
	"fmt"

	"github.com/a-h/templ"
	"github.com/rs/xid"
	"github.com/templwind/templwind"
)

// AlertType defines the type of alert.
// It can be one of the following: info, success, warning, error.
type AlertType string

const (
	TypeInfo    AlertType = "info"    // Informational alert
	TypeSuccess AlertType = "success" // Success alert
	TypeWarning AlertType = "warning" // Warning alert
	TypeError   AlertType = "error"   // Error alert
)

// isInfo returns true if the alert type is info.
func (t AlertType) isInfo() bool {
	return t == TypeInfo
}

// isSuccess returns true if the alert type is success.
func (t AlertType) isSuccess() bool {
	return t == TypeSuccess
}

// isWarning returns true if the alert type is warning.
func (t AlertType) isWarning() bool {
	return t == TypeWarning
}

// isError returns true if the alert type is error.
func (t AlertType) isError() bool {
	return t == TypeError
}

// Props defines the properties for the alert component.
type Props struct {
	ID            string            // Unique identifier for the alert
	Type          AlertType         // Type of the alert (info, success, warning, error)
	Title         string            // Title of the alert
	Buttons       []templ.Component // Array of buttons to display in the alert
	Message       string            // Message to display in the alert
	HideDuration  string            // Duration (in milliseconds) to hide the alert automatically
	Hide          bool              // Whether to hide the alert automatically
	IconComponent templ.Component   // Custom icon component for the alert
	IconSVG       string            // Custom SVG icon for the alert
	Shadow        bool              // Whether the alert should have a shadow
	CloseButton   bool              // Whether the alert should have a close button
	Class         string            // Custom css for the alert
}

// New creates a new alert component with optional properties.
// Example usage:
// alert := alert.New(
//
//	alert.WithType(alert.TypeSuccess),
//	alert.WithMessage("Your action was successful."),
//	alert.WithCloseButton(true),
//
// )
// This will create a success alert with a close button and a custom message.
func New(props ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, props...)
}

// NewWithProps creates a new alert component with the given properties.
// Example usage:
//
//	props := &alert.Props{
//	    Type:         alert.TypeWarning,
//	    Message:      "This is a warning alert.",
//	    HideDuration: "5000",
//	}
//
// alert := alert.NewWithProps(props)
func NewWithProps(props *Props) templ.Component {
	return templwind.NewWithProps(tpl, props)
}

// WithProps builds the properties with the given options.
// Example usage:
// props := alert.WithProps(
//
//	alert.WithType(alert.TypeError),
//	alert.WithMessage("An error occurred."),
//	alert.WithShadow(true),
//
// )
// alert := alert.NewWithProps(props)
func WithProps(props ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, props...)
}

// defaultProps provides the default properties for the alert component.
func defaultProps() *Props {
	return &Props{
		ID:           fmt.Sprintf("alert-%s", xid.New().String()),
		HideDuration: "3000", // default to 3 seconds
		IconSVG: `<svg
						xmlns="http://www.w3.org/2000/svg"
						fill="inherit"
						viewBox="0 0 24 24"
						class="w-6 h-6 shrink-0 stroke-info"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
						></path>
					</svg>`,
	}
}

// WithID sets the ID of the alert.
// Example usage:
// alert := alert.New(alert.WithID("custom-id"))
func WithID(id string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.ID = id
	}
}

// WithTitle sets the title of the alert.
// Example usage:
// alert := alert.New(alert.WithTitle("Alert Title"))
func WithTitle(title string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Title = title
	}
}

// WithButtons sets the buttons for the alert.
// Example usage:
//
//	button := templ.ComponentFunc(func(ctx context.Context, w io.Writer) error {
//	    _, err := io.WriteString(w, `<button class="btn btn-primary" hx-get="./do-something">I am a button</button>`)
//	    return err
//	})
//
// alert := alert.New(alert.WithButtons(button))
func WithButtons(buttons ...templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Buttons = buttons
	}
}

// WithType sets the type of the alert.
// Example usage:
// alert := alert.New(alert.WithType(alert.TypeSuccess))
func WithType(t AlertType) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Type = t
	}
}

// WithMessage sets the message of the alert.
// Example usage:
// alert := alert.New(alert.WithMessage("This is a custom message"))
func WithMessage(m ...string) templwind.OptFunc[Props] {
	return func(p *Props) {
		message := ""
		if len(m) > 1 {
			for _, v := range m {
				message += fmt.Sprintf(`<div>%s</div>`, v)
			}
		} else {
			message = m[0]
		}
		p.Message = message
	}
}

// WithHideDuration sets the duration to hide the alert automatically.
// Example usage:
// alert := alert.New(alert.WithHideDuration(5000))
func WithHideDuration(d int) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.HideDuration = fmt.Sprintf("%d", d)
	}
}

// WithHide sets whether the alert should be hidden automatically.
// Example usage:
// alert := alert.New(alert.WithHide(true))
func WithHide(hide bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Hide = hide
	}
}

// WithIconComponent sets a custom icon component for the alert.
// Example usage:
//
//	icon := templ.ComponentFunc(func(ctx context.Context, w io.Writer) error {
//	    _, err := io.WriteString(w, `<svg ...>...</svg>`)
//	    return err
//	})
//
// alert := alert.New(alert.WithIconComponent(icon))
func WithIconComponent(icon templ.Component) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.IconComponent = icon
	}
}

// WithIconSVG sets a custom SVG icon for the alert.
// Example usage:
// alert := alert.New(alert.WithIconSVG("<svg ...>...</svg>"))
func WithIconSVG(svg string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.IconSVG = svg
	}
}

// WithShadow sets whether the alert should have a shadow.
// Example usage:
// alert := alert.New(alert.WithShadow(true))
func WithShadow(shadow bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Shadow = shadow
	}
}

// WithCloseButton sets whether the alert should have a close button.
// Example usage:
// alert := alert.New(alert.WithCloseButton(true))
func WithCloseButton(close bool) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.CloseButton = close
	}
}

// WithClass sets custom css for the alert.
// Example usage:
// alert := alert.New(alert.WithClass("mt-4;"))
func WithClass(class string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Class = class
	}
}
