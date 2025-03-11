package types

import "github.com/aws/aws-sdk-go/aws/session"

type EmailAuth struct {
	APIKey     string
	APISecret  string
	APIUrl     string
	AWSSession *session.Session
	Username   string
	Password   string
	SMTPServer string
	Port       string
	Domain     string
	AccountID  string
}
