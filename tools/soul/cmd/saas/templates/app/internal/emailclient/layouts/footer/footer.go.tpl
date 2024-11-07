package footer

import (
	"github.com/a-h/templ"
	templwind "github.com/templwind/soul"
)

type Props struct {
	UnsubscribeURL string
	PrivacyURL     string
	TermsURL       string
	CompanyName    string
	Address1       string
	Address2       string
	City           string
	State          string
	Zip            string
	Country        string
	Message        string
}

// New creates a new component
func New(opts ...templwind.OptFunc[Props]) templ.Component {
	return templwind.New(defaultProps, tpl, opts...)
}

// NewWithProps creates a new component with the given options
func NewWithProps(opt *Props) templ.Component {
	return templwind.NewWithProps(tpl, opt)
}

// WithProps builds the options with the given options
func WithProps(opts ...templwind.OptFunc[Props]) *Props {
	return templwind.WithProps(defaultProps, opts...)
}

func defaultProps() *Props {
	return &Props{}
}

func WithUnsubscribeURL(unsubscribeURL string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.UnsubscribeURL = unsubscribeURL
	}
}

func WithPrivacyURL(privacyURL string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.PrivacyURL = privacyURL
	}
}

func WithTermsURL(termsURL string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.TermsURL = termsURL
	}
}

func WithCompanyName(companyName string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.CompanyName = companyName
	}
}

func WithAddress1(address1 string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Address1 = address1
	}
}

func WithAddress2(address2 string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Address2 = address2
	}
}

func WithCity(city string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.City = city
	}
}

func WithState(state string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.State = state
	}
}

func WithZip(zip string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Zip = zip
	}
}

func WithCountry(country string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Country = country
	}
}

func WithMessage(message string) templwind.OptFunc[Props] {
	return func(p *Props) {
		p.Message = message
	}
}
