package mailchimp

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/emailclient/email"
	"{{ .serviceName }}/internal/emailclient/types"
)

type Client struct {
	APIKey string
	APIUrl string
}

func NewClient(auth *types.EmailAuth) *Client {
	return &Client{
		APIKey: auth.APIKey,
		APIUrl: auth.APIUrl,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(auth *types.EmailAuth) *Client {
	return NewClient(auth)
}

func (c *Client) Send(e *email.Props) error {
	payload := map[string]interface{}{
		"apikey": c.APIKey,
		"email": map[string]string{
			"from":    e.Sender,
			"to":      e.Recipient,
			"subject": e.Subject,
			"content": e.Body,
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	resp, err := http.Post(c.APIUrl, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to send email, status code: %d", resp.StatusCode)
	}

	return nil
}
