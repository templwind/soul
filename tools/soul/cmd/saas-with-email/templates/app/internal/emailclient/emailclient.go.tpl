package emailclient

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"net/url"
	"path"
	"strings"
	"time"

	"{{ .serviceName }}/internal/emailclient/email"
	"{{ .serviceName }}/internal/emailclient/layouts/footer"
	"{{ .serviceName }}/internal/emailclient/types"
	"{{ .serviceName }}/internal/models"
	"{{ .serviceName }}/internal/svc"
	stdTypes "{{ .serviceName }}/internal/types"

	"github.com/a-h/templ"
	"github.com/templwind/soul"
	"golang.org/x/net/html"
)

// Email struct to hold email details
type Email struct {
	SvcCtx *svc.ServiceContext
	Props  *email.Props
}

func newEmail(svcCtx *svc.ServiceContext) *Email {
	return &Email{
		SvcCtx: svcCtx,
	}
}

// SystemSend sends an email using the system email client
func SystemSend(svcCtx *svc.ServiceContext, layout, body func(props *email.Props) templ.Component, opts ...soul.OptFunc[email.Props]) error {

	defaultOpts := []soul.OptFunc[email.Props]{
		email.WithBrandName(svcCtx.Config.Site.CompanyName),
		email.WithBaseURL(svcCtx.Config.Site.BaseURL),
		func(props *email.Props) {
			// Create the footer component using props
			props.FooterComponent = footer.New(
				footer.WithCompanyName(svcCtx.Config.Site.CompanyName),
				footer.WithMessage("You're receiving this email because you signed up for {{ .serviceName }}."),
				footer.WithAddress1("324 Center St. Box 1726"),
				footer.WithCity("Provo"),
				footer.WithState("UT"),
				footer.WithZip("84603"),
				footer.WithCountry("USA"),
				footer.WithUnsubscribeURL(fmt.Sprintf("%s/unsubscribe?email=%s", props.BaseURL, props.RecipientEmail)),
				footer.WithPrivacyURL(fmt.Sprintf("%s/privacy", props.BaseURL)),
				footer.WithTermsURL(fmt.Sprintf("%s/terms", props.BaseURL)),
			)
		},
	}

	return Send(svcCtx, svcCtx.SystemEmailClient, layout, body, append(defaultOpts, opts...)...)
}

// Send sends an email using the given email client
func Send(svcCtx *svc.ServiceContext, client types.EmailClient, layout, body func(props *email.Props) templ.Component, opts ...soul.OptFunc[email.Props]) error {
	// create a new email
	e := newEmail(svcCtx)

	// set the service context
	e.SvcCtx = svcCtx

	// set the context
	ctx := context.Background()

	// build the email
	var buf bytes.Buffer
	assembledEmail, props := email.NewWithComponent(layout, body, opts...)
	if err := assembledEmail.Render(context.Background(), &buf); err != nil {
		return err
	}

	e.Props = props
	e.Props.Body = buf.String()

	// set a default sender if the sender is empty
	if e.Props.Sender == "" {
		e.Props.Sender = fmt.Sprintf("%s <%s>", svcCtx.Config.Site.CompanyName, svcCtx.Config.Email.From)
	}

	// make htmlToPlainText
	e.Props.PlainText = htmlToPlainText(e.Props.Body)

	// assemble the email address
	if e.Props.Recipient == "" && e.Props.RecipientEmail != "" {
		if e.Props.RecipientName != "" {
			e.Props.Recipient = fmt.Sprintf("%s <%s>", e.Props.RecipientName, e.Props.RecipientEmail)
		} else {
			e.Props.Recipient = e.Props.RecipientEmail
		}
	}

	// validate the email
	if err := e.validate(); err != nil {
		return err
	}

	// start a transaction
	tx, err := svcCtx.DB.Begin()
	if err != nil {
		log.Printf("failed to start transaction: %v", err)
		return err
	}

	// create the email_recipients record
	recipient := models.EmailRecipient{
		ID:        models.NewXid(),
		Email:     e.Props.RecipientEmail,
		AccountID: e.Props.AccountModel.ID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := recipient.Insert(ctx, tx); err != nil {
		tx.Rollback()
		log.Printf("failed to insert email recipient: %v", err)
		return err
	}

	// Create the email send record
	e.Props.EmailSendModel = &models.EmailSend{
		ID:            models.NewXid(),
		AccountID:     e.Props.AccountModel.ID,
		RecipientID:   recipient.ID,
		EmailTypeID:   types.EmailTypeTransactional.Int64(),
		CurrentStatus: models.EmailStatusQueued,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	if err := e.Props.EmailSendModel.Insert(ctx, tx); err != nil {
		tx.Rollback()
		log.Printf("failed to insert email send: %v", err)
		return err
	}

	if err := tx.Commit(); err != nil {
		log.Printf("failed to commit transaction: %v", err)
		return err
	}

	// set the email send xid
	e.Props.EmailSendXid = e.Props.EmailSendModel.ID

	// merge the data and add the footer
	e.Props.Body = e.enhanceEmailContent()

	return client.Send(e.Props)
}

func (e *Email) validate() error {
	if e.Props.Sender == "" {
		return fmt.Errorf("sender is required")
	}
	if e.Props.RecipientEmail == "" {
		return fmt.Errorf("recipient email is required")
	}
	if e.Props.Recipient == "" {
		return fmt.Errorf("recipient is required")
	}
	if e.Props.Subject == "" {
		return fmt.Errorf("subject is required")
	}
	if e.Props.Body == "" {
		return fmt.Errorf("body is required")
	}
	if e.Props.Body == "" {
		return fmt.Errorf("body is required")
	}
	if e.Props.FooterComponent == nil {
		return fmt.Errorf("footer component is required")
	}
	return nil
}

// htmlToPlainText converts HTML to plain text by stripping HTML tags.
func htmlToPlainText(htmlStr string) string {
	doc, err := html.Parse(strings.NewReader(htmlStr))
	if err != nil {
		return htmlStr // Fallback to the original HTML if parsing fails
	}

	var plainText strings.Builder
	var f func(*html.Node)
	f = func(n *html.Node) {
		if n.Type == html.TextNode {
			plainText.WriteString(n.Data)
			if n.Data != "" {
				plainText.WriteString("\n")
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			f(c)
		}
	}
	f(doc)

	return cleanUpWhitespace(plainText.String())
}

// cleanUpWhitespace removes excessive whitespace and cleans up the text.
func cleanUpWhitespace(text string) string {
	lines := strings.Split(text, "\n")
	var cleanedLines []string
	for _, line := range lines {
		trimmedLine := strings.TrimSpace(line)
		if trimmedLine != "" {
			cleanedLines = append(cleanedLines, trimmedLine)
		}
	}
	return strings.Join(cleanedLines, "\n")
}

const (
	PixelSuffix       = "pixel"
	UnsubscribeSuffix = "unsubscribe"
	ClickSuffix       = "click"
)

// enhanceEmailContent automatically inserts tracking links, adds a tracking pixel, replaces placeholders, and includes the footer.
func (e *Email) enhanceEmailContent() string {
	// Parse the HTML content
	doc, err := html.Parse(strings.NewReader(e.Props.Body))
	if err != nil {
		fmt.Println("Error parsing HTML:", err) // Log the error
		return e.Props.Body                     // Fallback to the original HTML if parsing fails
	}

	// Function to update href attributes with tracking links
	var f func(*html.Node)
	f = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "a" {
			for i := range n.Attr {
				if n.Attr[i].Key == "href" {
					originalLink := n.Attr[i].Val
					// Exclude the unsubscribe links from tracking
					// if !strings.Contains(originalLink, UnsubscribeSuffix) {
					trackingURL := e.TrackingURL(originalLink)
					n.Attr[i].Val = trackingURL
					// }
				}
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			f(c)
		}
	}
	// Apply the function to update all <a> tags in the initial content
	f(doc)

	// Render the modified HTML back to a string
	var buf bytes.Buffer
	if err := html.Render(&buf, doc); err != nil {
		fmt.Println("Error rendering HTML:", err) // Log the error
		return e.Props.Body                       // Fallback to the original HTML if rendering fails
	}

	enhancedContent := buf.String()

	// Insert the footer if it exists
	if e.Props.FooterComponent != nil {
		// Reuse the buffer for rendering the footer
		buf.Reset()
		if err := e.Props.FooterComponent.Render(context.Background(), &buf); err == nil {
			// Append the footer where the placeholder is
			footerContent := buf.String()

			// Parse the footer content to update the URLs
			footerDoc, err := html.Parse(strings.NewReader(footerContent))
			if err == nil {
				// Apply the function to update all <a> tags in the footer
				f(footerDoc)

				// Render the modified footer HTML back to a string
				buf.Reset()
				if err := html.Render(&buf, footerDoc); err == nil {
					footerContent = buf.String()
				}
			}

			// Replace the footer placeholder with the updated footer content
			enhancedContent = strings.ReplaceAll(enhancedContent, "[footer]", footerContent)
		}
	}

	// Insert the tracking pixel before the closing body tag
	trackingPixel := fmt.Sprintf(`<img src="%s/open?email=%s&id=%s" width="1" height="1" style="display:block;width:1px;height:1px;" />`, e.Props.EmailBaseURL, url.QueryEscape(e.Props.Recipient), e.Props.EmailSendXid.String())
	enhancedContent = strings.Replace(enhancedContent, "</body>", trackingPixel+"</body>", 1)

	// Replace placeholders
	values := PlaceholderValues{
		UnsubscribeURL: e.Props.UnsubscribeURL,
		RecipientName:  e.Props.UserModel.Email,
		FirstName:      e.Props.UserModel.FirstName,
		LastName:       e.Props.UserModel.LastName,
		Email:          e.Props.Recipient,
		Company:        stdTypes.NewStringFromNull(e.Props.AccountModel.CompanyName),
		OptionalTags:   e.Props.Headers,
	}

	enhancedContent = e.replacePlaceholders(enhancedContent, values)

	return enhancedContent
}

// PlaceholderValues holds the values for the placeholders that can't be derived on their own
type PlaceholderValues struct {
	UnsubscribeURL string
	RecipientName  string
	FirstName      string
	LastName       string
	Email          string
	Company        string
	OptionalTags   map[string]string
}

// replacePlaceholders replaces placeholders in the content with actual values
func (e *Email) replacePlaceholders(content string, values PlaceholderValues) string {
	// Get current time
	currentTime := time.Now()

	// Common placeholders
	content = strings.ReplaceAll(content, "[unsubscribe]", values.UnsubscribeURL)
	content = strings.ReplaceAll(content, "<unsubscribe>", fmt.Sprintf(`<a href="%s">`, values.UnsubscribeURL))
	content = strings.ReplaceAll(content, "</unsubscribe>", "</a>")
	content = strings.ReplaceAll(content, "[name]", values.RecipientName)
	content = strings.ReplaceAll(content, "[first_name]", values.FirstName)
	content = strings.ReplaceAll(content, "[last_name]", values.LastName)
	content = strings.ReplaceAll(content, "[email]", values.Email)
	content = strings.ReplaceAll(content, "[company]", values.Company)
	content = strings.ReplaceAll(content, "[date]", currentTime.Format("2006-01-02"))
	content = strings.ReplaceAll(content, "[time]", currentTime.Format("15:04:05"))
	content = strings.ReplaceAll(content, "[datetime]", currentTime.Format("2006-01-02 15:04:05"))
	content = strings.ReplaceAll(content, "[year]", currentTime.Format("2006"))
	content = strings.ReplaceAll(content, "[month]", currentTime.Format("01"))
	content = strings.ReplaceAll(content, "[day]", currentTime.Format("02"))

	// Replace optional tags
	for tag, value := range values.OptionalTags {
		placeholder := fmt.Sprintf("[%s]", tag)
		content = strings.ReplaceAll(content, placeholder, value)
	}

	return content
}

// TrackingURL function to generate tracking URLs
func (e *Email) TrackingURL(originalLink string) string {
	u, err := url.Parse(e.Props.EmailBaseURL)
	if err != nil {
		fmt.Println("Error parsing URL:", err) // Log the error
		return ""                              // or handle error accordingly
	}

	// append the click path
	u.Path = path.Join(u.Path, ClickSuffix)

	// Construct the path and query parameters
	q := u.Query()
	q.Set("id", e.Props.EmailSendModel.ID.String())
	q.Set("email", e.Props.Recipient)
	q.Set("url", originalLink)
	u.RawQuery = q.Encode()

	return u.String()
}
