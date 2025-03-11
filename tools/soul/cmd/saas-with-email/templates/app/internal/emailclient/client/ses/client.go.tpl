package ses

import (
	"fmt"

	"{{ .serviceName }}/internal/emailclient/email"
	"{{ .serviceName }}/internal/emailclient/types"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ses"
)

type Client struct {
	Client *ses.SES
}

// MustNewClient creates a new Client and panics if there is an error
func MustNewClient(auth *types.EmailAuth) *Client {
	return &Client{
		Client: ses.New(auth.AWSSession),
	}
}

func NewClient(auth *types.EmailAuth) (*Client, error) {
	sess, err := session.NewSession(&aws.Config{
		Region: auth.AWSSession.Config.Region,
	})
	if err != nil {
		return nil, err
	}

	return &Client{
		Client: ses.New(sess),
	}, nil
}

func (c *Client) Send(e *email.Props) error {
	plainText := e.PlainText

	var tags []*ses.MessageTag
	for key, value := range e.Headers {
		tags = append(tags, &ses.MessageTag{
			Name:  aws.String(key),
			Value: aws.String(value),
		})
	}

	input := &ses.SendEmailInput{
		Destination: &ses.Destination{
			ToAddresses: []*string{
				aws.String(e.Recipient),
			},
		},
		Message: &ses.Message{
			Body: &ses.Body{
				Html: &ses.Content{
					Charset: aws.String("UTF-8"),
					Data:    aws.String(e.Body),
				},
				Text: &ses.Content{
					Charset: aws.String("UTF-8"),
					Data:    aws.String(plainText),
				},
			},
			Subject: &ses.Content{
				Charset: aws.String("UTF-8"),
				Data:    aws.String(e.Subject),
			},
		},
		Source: aws.String(e.Sender),
		Tags:   tags,
	}

	_, err := c.Client.SendEmail(input)
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	return nil
}
