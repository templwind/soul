package ontraport

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/emailclient/email"
)

type Client struct {
	APIKey string
	APIUrl string
}

func NewClient(apiKey, url string) *Client {
	return &Client{
		APIKey: apiKey,
		APIUrl: url,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(apiKey, url string) *Client {
	return NewClient(apiKey, url)
}

func (c *Client) Send(e *email.Props) error {
	payload := map[string]interface{}{
		"api_key": c.APIKey,
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
