package mandrill

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
	url := "https://mandrillapp.com/api/1.0/messages/send.json"

	payload := map[string]interface{}{
		"key": c.APIKey,
		"message": map[string]interface{}{
			"from_email": e.Sender,
			"to": []map[string]string{
				{"email": e.Recipient},
			},
			"subject": e.Subject,
			"html":    e.Body,
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to send email, status code: %d", resp.StatusCode)
	}

	return nil
}
