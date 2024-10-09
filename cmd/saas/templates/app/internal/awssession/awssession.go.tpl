package awssession

import (
	"fmt"
	"time"

	"{{ .serviceName }}/internal/config"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
)

// Config holds the configuration for the AWS session
type Config struct {
	config.AWS
	MaxRetries    int
	RetryInterval time.Duration
}

// NewSession creates a new AWS session with the provided configuration and automatic reconnects
func NewSession(cfg Config) (*session.Session, error) {
	var sess *session.Session
	var err error

	for i := 0; i < cfg.MaxRetries; i++ {
		sess, err = session.NewSession(&aws.Config{
			Region:      aws.String(cfg.Region),
			Credentials: credentials.NewStaticCredentials(cfg.AccessKeyID, cfg.SecretAccessKey, ""),
		})
		if err == nil {
			return sess, nil
		}

		fmt.Printf("failed to create AWS session, retrying... (%d/%d)\n", i+1, cfg.MaxRetries)
		time.Sleep(cfg.RetryInterval)
	}

	return nil, fmt.Errorf("failed to create AWS session after %d retries: %w", cfg.MaxRetries, err)
}

// MustNewSession creates a new AWS session and panics if there is an error
func MustNewSession(cfg Config) *session.Session {
	sess, err := NewSession(cfg)
	if err != nil {
		panic(fmt.Sprintf("failed to create AWS session: %v", err))
	}
	return sess
}
