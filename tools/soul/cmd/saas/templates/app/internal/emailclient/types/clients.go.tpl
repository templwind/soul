package types

import "{{ .serviceName }}/internal/emailclient/email"

// EmailClient interface defines the method to send emails
type EmailClient interface {
	Send(email *email.Props) error
}

type ClientType string

const (
	ActiveCampaignClient   ClientType = "activecampaign"
	AdobeClient            ClientType = "adobe"
	AWeberClient           ClientType = "aweber"
	BenchmarkClient        ClientType = "benchmark"
	BluecoreClient         ClientType = "bluecore"
	BrevoClient            ClientType = "brevo"
	CampaignMonitorClient  ClientType = "campaignmonitor"
	ConstantContactClient  ClientType = "constantcontact"
	ConvertKitClient       ClientType = "convertkit"
	CopperClient           ClientType = "copper"
	DotdigitalClient       ClientType = "dotdigital"
	DripClient             ClientType = "drip"
	ElasticEmailClient     ClientType = "elasticemail"
	EloquaClient           ClientType = "eloqua"
	EmmaClient             ClientType = "emma"
	FreshsalesClient       ClientType = "freshsales"
	GetResponseClient      ClientType = "getresponse"
	GmailClient            ClientType = "gmail"
	GMassClient            ClientType = "gmass"
	HubSpotClient          ClientType = "hubspot"
	IContactClient         ClientType = "icontact"
	KeapClient             ClientType = "keap"
	KlaviyoClient          ClientType = "klaviyo"
	MailchimpClient        ClientType = "mailchimp"
	MailerLiteClient       ClientType = "mailerlite"
	MailerSendClient       ClientType = "mailersend"
	MailgunClient          ClientType = "mailgun"
	MailjetClient          ClientType = "mailjet"
	MailtrapClient         ClientType = "mailtrap"
	MandrillClient         ClientType = "mandrill"
	MoosendClient          ClientType = "moosend"
	NimbleClient           ClientType = "nimble"
	OmnisendClient         ClientType = "omnisend"
	OntraportClient        ClientType = "ontraport"
	PabblyClient           ClientType = "pabbly"
	PepipostClient         ClientType = "pepipost"
	PipedriveClient        ClientType = "pipedrive"
	PostmarkClient         ClientType = "postmark"
	SalesforceClient       ClientType = "salesforce"
	SendGridClient         ClientType = "sendgrid"
	SendPulseClient        ClientType = "sendpulse"
	SESClient              ClientType = "ses"
	SharpSpringClient      ClientType = "sharpspring"
	SMTPClient             ClientType = "smtp"
	SparkPostClient        ClientType = "sparkpost"
	VerticalResponseClient ClientType = "verticalresponse"
	ZohoClient             ClientType = "zoho"
)
