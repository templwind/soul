package postmark

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/emailclient/email"
)

type Client struct {
	APIKey string
}

func NewClient(apiKey string) *Client {
	return &Client{
		APIKey: apiKey,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(apiKey string) *Client {
	return NewClient(apiKey)
}

func (c *Client) Send(e *email.Props) error {
	url := "https://api.postmarkapp.com/email"

	payload := map[string]interface{}{
		"From":     e.Sender,
		"To":       e.Recipient,
		"Subject":  e.Subject,
		"TextBody": e.PlainText,
		"HtmlBody": e.Body,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Postmark-Server-Token", c.APIKey)
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
