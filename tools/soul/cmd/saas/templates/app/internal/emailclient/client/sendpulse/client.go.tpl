package sendpulse

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"

	"{{ .serviceName }}/internal/emailclient/email"
)

type Client struct {
	APIKey    string
	APISecret string
}

func NewClient(apiKey, apiSecret string) *Client {
	return &Client{
		APIKey:    apiKey,
		APISecret: apiSecret,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(apiKey, apiSecret string) *Client {
	return NewClient(apiKey, apiSecret)
}

func (c *Client) Send(e *email.Props) error {
	url := "https://api.sendpulse.com/smtp/emails"

	payload := map[string]interface{}{
		"html":    e.Body,
		"text":    e.PlainText,
		"subject": e.Subject,
		"from": map[string]string{
			"name":  "Sender Name",
			"email": e.Sender,
		},
		"to": []map[string]string{
			{"email": e.Recipient},
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.APIKey)
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
