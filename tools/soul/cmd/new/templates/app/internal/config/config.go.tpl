package config

import (
	{{.imports}}
)

type Config struct {
	webserver.WebServerConf
	db.DBConfig
	Nats        NatsConfig
	Redis       RedisConfig 
	Environment string
	EmbeddedFS  map[string]*embed.FS
	{{.auth -}}
	{{.jwtTrans -}}
	TotalInstances   int
	RateLimiters     map[string]ratelimiter.RateLimiterConfig
	GPT              GPT `yaml:"GPT,omitempty"`
	Anthropic        Anthropic `yaml:"Anthropic,omitempty"`
	AWS              AWS `yaml:"AWS,omitempty"`
	DigitalOcean     DigitalOcean `yaml:"DigitalOcean,omitempty"`
	Stripe           Stripe `yaml:"Stripe,omitempty"`
	Email            Email `yaml:"Email,omitempty"`
	Admin            struct {
		AuthorizedDomains []string 
	} `yaml:"Admin,omitempty"`
}

type NatsConfig struct {
	URL string
}

type RedisConfig struct {
	URL string
}

type GPT struct {
	Endpoint       string
	APIKey         string
	OrgID          string
	Model          string
	DallEModel     string `yaml:"DallEModel,omitempty"`
	DallEEndpoint  string `yaml:"DallEEndpoint,omitempty"`
	TotalRPM       int
	MaxConcurrency int
}

type Anthropic struct {
	APIKey         string
	Model          string
	Endpoint       string
	RequestsPerMin int
}

type Stripe struct {
	SecretKey      string
	PublishableKey string
	WebhookSecret  string
}

type Email struct {
	From             string // Sender's email address
	ReplyTo          string // Address to receive replies, optional but recommended
	BaseURL          string // Base URL for links
	UnsubscribeURL   string // URL to handle unsubscriptions
	UnsubscribeText  string // Text for unsubscribe link
	ListUnsubscribe  string // List-Unsubscribe header
	PrivacyPolicyURL string // Link to your privacy policy
	CompanyInfo      struct {
		Name         string // Company name
		Address      string // Company address
		Phone        string // Company phone number
		SupportEmail string // Support email address
	}
}

type AWS struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
}

type DigitalOcean struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
	Endpoint        string
}

