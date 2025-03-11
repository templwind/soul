package freshsales

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/emailclient/email"
)

type Client struct {
	APIKey string
	URL    string
}

func NewClient(apiKey, url string) *Client {
	return &Client{
		APIKey: apiKey,
		URL:    url,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(apiKey, url string) *Client {
	return NewClient(apiKey, url)
}

func (c *Client) Send(e *email.Props) error {
	payload := map[string]interface{}{
		"from":    e.Sender,
		"to":      []string{e.Recipient},
		"subject": e.Subject,
		"html":    e.Body,
		"text":    e.PlainText,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", c.URL, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Token token="+c.APIKey)
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
