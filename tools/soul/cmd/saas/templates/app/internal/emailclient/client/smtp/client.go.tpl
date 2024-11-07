package smtp

import (
	"crypto/tls"
	"fmt"
	"net/smtp"

	"{{ .serviceName }}/internal/emailclient/email"
	"{{ .serviceName }}/internal/emailclient/types"
)

type Client struct {
	Username   string
	Password   string
	SMTPServer string
	SMTPPort   string
}

func NewClient(auth *types.EmailAuth) *Client {
	return &Client{
		Username:   auth.Username,
		Password:   auth.Password,
		SMTPServer: auth.SMTPServer,
		SMTPPort:   auth.Port,
	}
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(auth *types.EmailAuth) *Client {
	return NewClient(auth)
}

func (c *Client) Send(e *email.Props) error {
	auth := smtp.PlainAuth("", c.Username, c.Password, c.SMTPServer)

	msg := []byte("To: " + e.Recipient + "\r\n" +
		"Subject: " + e.Subject + "\r\n" +
		"MIME-version: 1.0;\r\n" +
		"Content-Type: text/html; charset=\"UTF-8\";\r\n\r\n" +
		e.Body)

	tlsconfig := &tls.Config{
		InsecureSkipVerify: true,
		ServerName:         c.SMTPServer,
	}

	conn, err := tls.Dial("tcp", c.SMTPServer+":"+c.SMTPPort, tlsconfig)
	if err != nil {
		return fmt.Errorf("failed to connect to %s: %w", c.SMTPServer, err)
	}

	client, err := smtp.NewClient(conn, c.SMTPServer)
	if err != nil {
		return fmt.Errorf("failed to create SMTP client: %w", err)
	}

	if err = client.Auth(auth); err != nil {
		return fmt.Errorf("failed to authenticate: %w", err)
	}

	if err = client.Mail(c.Username); err != nil {
		return fmt.Errorf("failed to set c: %w", err)
	}

	if err = client.Rcpt(e.Recipient); err != nil {
		return fmt.Errorf("failed to set recipient: %w", err)
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("failed to get data writer: %w", err)
	}

	_, err = w.Write(msg)
	if err != nil {
		return fmt.Errorf("failed to write message: %w", err)
	}

	err = w.Close()
	if err != nil {
		return fmt.Errorf("failed to close data writer: %w", err)
	}

	return client.Quit()
}
