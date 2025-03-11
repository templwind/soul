package register

// import (
// 	"bytes"
// 	"context"
// 	"fmt"
// 	"log"
// 	"net/http"
// 	"time"

// 	"{{ .serviceName }}/internal/config"
// 	"{{ .serviceName }}/internal/email"
// 	"{{ .serviceName }}/internal/email/templates"
// 	"{{ .serviceName }}/internal/email/templates/goshare"
// 	"{{ .serviceName }}/internal/models"
// 	"{{ .serviceName }}/internal/svc"
// 	"{{ .serviceName }}/internal/types"

// 	"github.com/a-h/templ"
// 	"github.com/templwind/soul"
// )

// // Props defines the options for the register component, embedding templates.Props
// type Props struct {
// 	Request        *http.Request
// 	Config         *config.Config
// 	AccountID      int64
// 	RecipientEmail string
// 	Subject        string
// 	Lead           string
// 	ReferralLink   string
// 	ConfirmLink    string
// 	TrackingID     string
// 	PreviewText    string
// 	BaseURL        string
// 	EmailBaseURL   string
// 	Password       string
// 	AccountModel   *models.Account
// 	UserModel      *models.User
// 	EmailSendModel *models.EmailSend
// 	BrandName      string
// }

// // Send method to render and send the email
// func Send(ctx context.Context, svcCtx *svc.ServiceContext, props *Props) error {
// 	// Render the email template
// 	var buf bytes.Buffer
// 	emailTemplate := NewWithProps(props)
// 	err := emailTemplate.Render(ctx, &buf)
// 	if err != nil {
// 		log.Printf("failed to render email template: %v", err)
// 		return err
// 	}

// 	// start a transaction
// 	tx, err := svcCtx.DB.Begin()
// 	if err != nil {
// 		log.Printf("failed to start transaction: %v", err)
// 		return err
// 	}

// 	// log.Fatalf("accountModel: %#v", props.AccountModel)

// 	// create the email_recipients record
// 	recipient := models.EmailRecipient{
// 		ID:        models.NewXid(),
// 		Email:     props.RecipientEmail,
// 		AccountID: props.AccountModel.ID,
// 		CreatedAt: time.Now(),
// 		UpdatedAt: time.Now(),
// 	}
// 	if err := recipient.Insert(ctx, tx); err != nil {
// 		tx.Rollback()
// 		log.Printf("failed to insert email recipient: %v", err)
// 		return err
// 	}

// 	// Create the email send record
// 	emailSend := &models.EmailSend{
// 		ID:            models.NewXid(),
// 		AccountID:     props.AccountModel.ID,
// 		RecipientID:   recipient.ID,
// 		EmailTypeID:   types.EmailTypeTransactional.Int64(),
// 		CurrentStatus: models.EmailStatusQueued,
// 		CreatedAt:     time.Now(),
// 		UpdatedAt:     time.Now(),
// 	}

// 	if err := emailSend.Insert(ctx, tx); err != nil {
// 		tx.Rollback()
// 		log.Printf("failed to insert email send: %v", err)
// 		return err
// 	}

// 	if err := tx.Commit(); err != nil {
// 		log.Printf("failed to commit transaction: %v", err)
// 		return err
// 	}

// 	// Create the email
// 	footer := new(templates.FooterProps)
// 	emailToSend := email.NewEmail(
// 		goshare.Template,
// 		goshare.Template,
// 		email.WithConfig(svcCtx.Config),
// 		email.WithSender(fmt.Sprintf("%s <%s>", svcCtx.Config.Site.CompanyName, svcCtx.Config.Email.From)),
// 		email.WithRecipient(props.RecipientEmail),
// 		email.WithSubject(props.Subject),
// 		email.WithBody(buf.String()),
// 		email.WithAccountID(props.AccountID),
// 		email.WithFooter(footer.New(
// 			footer.WithMessage("You're receiving this email because you signed up for our prelaunch. If you have any questions, please reply to this email."),
// 			footer.WithAddress1("324 Center St. Box 1726"),
// 			footer.WithCity("Provo"),
// 			footer.WithState("UT"),
// 			footer.WithZip("84603"),
// 			footer.WithCountry("USA"),
// 			footer.WithCompanyName(svcCtx.Config.Site.CompanyName),
// 			footer.WithPrivacyURL(fmt.Sprintf("%s/privacy", props.BaseURL)),
// 			footer.WithTermsURL(fmt.Sprintf("%s/terms", props.BaseURL)),
// 		)),
// 		email.WithEmailSendModel(emailSend),
// 		email.WithAccountModel(props.AccountModel),
// 		email.WithUserModel(props.UserModel),
// 		email.WithEmailBaseURL(props.EmailBaseURL),
// 		email.WithUnsubscribeURL(fmt.Sprintf("%s/unsubscribe?email=%s", props.BaseURL, props.RecipientEmail)),
// 	)

// 	// // Queue the email for sending using Temporal
// 	// options := client.StartWorkflowOptions{
// 	// 	ID:        fmt.Sprintf("send_email_workflow_%s", props.TrackingID),
// 	// 	TaskQueue: "EMAIL_QUEUE",
// 	// }
// 	// workflowRun, err := svcCtx.EmailService.Client().ExecuteWorkflow(ctx, options, svcCtx.EmailService.SendEmailWorkflow.SendEmailWorkflow, emailToSend)
// 	// if err != nil {
// 	// 	log.Printf("Unable to start SendEmail workflow: %v", err)
// 	// 	return err
// 	// }

// 	// log.Printf("Started SendEmail workflow with ID: %s", workflowRun.GetID())
// 	// return nil

// 	// Send the email

// 	err = svcCtx.SystemEmailClient.Send(emailToSend)
// 	if err != nil {
// 		log.Printf("failed to send email: %v", err)
// 		return err
// 	}

// 	return err
// }

// // New creates a new component
// func New(opts ...soul.OptFunc[Props]) templ.Component {
// 	return soul.New(defaultProps, tpl, opts...)
// }

// // NewWithProps creates a new component with the given options
// func NewWithProps(opt *Props) templ.Component {
// 	return soul.NewWithProps(tpl, opt)
// }

// // WithProps builds the options with the given options
// func WithProps(opts ...soul.OptFunc[Props]) *Props {
// 	return soul.WithProps(defaultProps, opts...)
// }

// func defaultProps() *Props {
// 	return &Props{}
// }

// func WithAccountID(accountID int64) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.AccountID = accountID
// 	}
// }

// func WithBaseURL(baseURL string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.BaseURL = baseURL
// 	}
// }

// func WithPassword(password string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.Password = password
// 	}
// }

// func WithSubject(subject string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.Subject = subject
// 	}
// }

// func WithRecipientEmail(email string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.RecipientEmail = email
// 	}
// }

// func WithReferralLink(referralLink string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.ReferralLink = referralLink
// 	}
// }

// func WithTrackingID(trackingID string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.TrackingID = trackingID
// 	}
// }

// func WithPreviewText(previewText string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.PreviewText = previewText
// 	}
// }

// func WithConfig(c *config.Config) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.Config = c
// 		p.BrandName = c.Site.CompanyName
// 	}
// }

// func WithLead(lead string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.Lead = lead
// 	}
// }

// func WithRequest(r *http.Request) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.Request = r
// 	}
// }

// func WithAccountModel(m *models.Account) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.AccountModel = m
// 	}
// }

// func WithUserModel(m *models.User) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.UserModel = m
// 	}
// }

// func WithEmailSendModel(m *models.EmailSend) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.EmailSendModel = m
// 	}
// }

// func WithEmailBaseURL(baseURL string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.EmailBaseURL = baseURL
// 	}
// }

// func WithConfirmLink(confirmLink string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.ConfirmLink = confirmLink
// 	}
// }

// func WithBrandName(brandName string) soul.OptFunc[Props] {
// 	return func(p *Props) {
// 		p.BrandName = brandName
// 	}
// }
