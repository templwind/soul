package brevo

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
}

func NewClient(auth *types.EmailAuth) *Client {
	return &Client{
		APIKey: auth.APIKey,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(auth *types.EmailAuth) *Client {
	return NewClient(auth)
}

func (c *Client) Send(e *email.Props) error {
	url := "https://api.sendinblue.com/v3/smtp/email"

	payload := map[string]interface{}{
		"sender": map[string]string{
			"email": e.Sender,
		},
		"to": []map[string]string{
			{"email": e.Recipient},
		},
		"subject":     e.Subject,
		"htmlContent": e.Body,
		"textContent": e.PlainText,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("api-key", c.APIKey)
	req.Header.Set("Content-Type", "application/json")

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
