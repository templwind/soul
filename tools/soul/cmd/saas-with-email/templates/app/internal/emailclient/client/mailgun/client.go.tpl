package mailgun

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"{{ .serviceName }}/internal/emailclient/email"
	"{{ .serviceName }}/internal/emailclient/types"
)

type Client struct {
	Domain string
	APIKey string
}

func NewClient(auth *types.EmailAuth) *Client {
	return &Client{
		Domain: auth.Domain,
		APIKey: auth.APIKey,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(auth *types.EmailAuth) *Client {
	return NewClient(auth)
}

func (c *Client) Send(e *email.Props) error {
	form := url.Values{}
	form.Add("from", e.Sender)
	form.Add("to", e.Recipient)
	form.Add("subject", e.Subject)
	form.Add("text", e.PlainText)
	form.Add("html", e.Body)

	req, err := http.NewRequest("POST", "https://api.mailgun.net/v3/"+c.Domain+"/messages", strings.NewReader(form.Encode()))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.SetBasicAuth("api", c.APIKey)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to send email, status code: %d", resp.StatusCode)
	}

	return nil
}
