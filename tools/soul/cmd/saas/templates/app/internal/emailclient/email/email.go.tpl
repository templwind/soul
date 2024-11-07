package email

import (
	"{{ .serviceName }}/internal/models"
	"strconv"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
)

// Props struct to hold email details
type Props struct {
	Sender          string
	RecipientName   string
	RecipientEmail  string
	Recipient       string
	Subject         string
	Body            string
	PlainText       string
	Headers         map[string]string
	BaseURL         string
	UnsubscribeURL  string
	EmailBaseURL    string
	PreviewText     string
	Lead            string
	ConfirmLink     string
	ReferralLink    string
	DownloadLink    string
	Password        string
	Code            string
	BrandName       string
	Meta            map[string]string
	EmailSendXid    models.Xid
	BodyComponent   templ.Component
	FooterComponent templ.Component
	AccountModel    *models.Account
	UserModel       *models.User
	EmailSendModel  *models.EmailSend
}

// // layout is the design/layout component layout
// // content is the content/body component layout
func NewWithComponent(layout, body func(props *Props) templ.Component, opts ...soul.OptFunc[Props]) (templ.Component, *Props) {
	props := DefaultProps()
	for _, opt := range opts {
		opt(props)
	}
	props.BodyComponent = body(props)
	return layout(props), props
}

// New creates a new component
func New(opts ...soul.OptFunc[Props]) templ.Component {
	return soul.New(DefaultProps, tpl, opts...)
}

// NewWithEmail creates a new component with the given options
func NewWithEmail(opt *Props) templ.Component {
	return soul.NewWithProps(tpl, opt)
}

// WithEmail builds the options with the given options
func WithEmail(opts ...soul.OptFunc[Props]) *Props {
	return soul.WithProps(DefaultProps, opts...)
}

func DefaultProps() *Props {
	return &Props{
		Headers: make(map[string]string),
		Meta:    make(map[string]string),
	}
}

// WithSender sets the sender of the email
func WithSender(sender string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Sender = sender
	}
}

// WithRecipientName sets the recipient name of the email
func WithRecipientName(recipientName string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.RecipientName = recipientName
	}
}

// WithRecipientEmail sets the recipient email of the email
func WithRecipientEmail(recipientEmail string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.RecipientEmail = recipientEmail
	}
}

// WithSubject sets the subject of the email
func WithSubject(subject string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Subject = subject
	}
}

// WithBody sets the body of the email
func WithBody(body string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Body = body
	}
}

func WithHeaders(headers map[string]string) soul.OptFunc[Props] {
	return func(e *Props) {
		// merge the headers
		for k, v := range headers {
			e.Headers[k] = v
		}
	}
}

func WithAccountID(accountID int64) soul.OptFunc[Props] {
	return func(e *Props) {
		// convert the int64 to string
		accountIDStr := strconv.FormatInt(accountID, 10)
		e.Headers["X-Account-ID"] = accountIDStr
	}
}

func WithSendID(sendID models.Xid) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Headers["X-Send-ID"] = sendID.String()
	}
}

func WithFooterComponent(footerComponent templ.Component) soul.OptFunc[Props] {
	return func(e *Props) {
		e.FooterComponent = footerComponent
	}
}

func WithEmailSendXid(emailSendXid models.Xid) soul.OptFunc[Props] {
	return func(e *Props) {
		e.EmailSendXid = emailSendXid
		e.Headers["X-Props-Send-ID"] = emailSendXid.String()
	}
}

func WithBaseURL(baseURL string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.BaseURL = baseURL
	}
}

func WithUnsubscribeURL(unsubscribeURL string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.UnsubscribeURL = unsubscribeURL
	}
}

func WithEmailBaseURL(emailBaseURL string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.EmailBaseURL = emailBaseURL
	}
}

func WithDownloadLink(downloadLink string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.DownloadLink = downloadLink
	}
}

func WithAccountModel(accountModel *models.Account) soul.OptFunc[Props] {
	return func(e *Props) {
		e.AccountModel = accountModel
	}
}

func WithUserModel(userModel *models.User) soul.OptFunc[Props] {
	return func(e *Props) {
		e.UserModel = userModel
	}
}

func WithEmailSendModel(emailSendModel *models.EmailSend) soul.OptFunc[Props] {
	return func(e *Props) {
		e.EmailSendModel = emailSendModel
	}
}

func WithMeta(key, value string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Meta[key] = value
	}
}

func WithPreviewText(previewText string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.PreviewText = previewText
	}
}

func WithLead(lead string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Lead = lead
	}
}

func WithConfirmLink(confirmLink string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.ConfirmLink = confirmLink
	}
}

func WithReferralLink(referralLink string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.ReferralLink = referralLink
	}
}

func WithPassword(password string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Password = password
	}
}

func WithCode(code string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Code = code
	}
}

func WithBrandName(brandName string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.BrandName = brandName
	}
}

func WithPlainText(plainText string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.PlainText = plainText
	}
}

func WithRecipient(recipient string) soul.OptFunc[Props] {
	return func(e *Props) {
		e.Recipient = recipient
	}
}

func WithBodyComponent(bodyComponent templ.Component) soul.OptFunc[Props] {
	return func(e *Props) {
		e.BodyComponent = bodyComponent
	}
}
