package client

import (
	"fmt"

	"{{ .serviceName }}/internal/emailclient/client/activecampaign"
	"{{ .serviceName }}/internal/emailclient/client/adobe"
	"{{ .serviceName }}/internal/emailclient/client/aweber"
	"{{ .serviceName }}/internal/emailclient/client/brevo"
	"{{ .serviceName }}/internal/emailclient/client/constantcontact"
	"{{ .serviceName }}/internal/emailclient/client/convertkit"
	"{{ .serviceName }}/internal/emailclient/client/drip"
	"{{ .serviceName }}/internal/emailclient/client/getresponse"
	"{{ .serviceName }}/internal/emailclient/client/gmail"
	"{{ .serviceName }}/internal/emailclient/client/hubspot"
	"{{ .serviceName }}/internal/emailclient/client/klaviyo"
	"{{ .serviceName }}/internal/emailclient/client/mailchimp"
	"{{ .serviceName }}/internal/emailclient/client/mailgun"
	"{{ .serviceName }}/internal/emailclient/client/mailjet"
	"{{ .serviceName }}/internal/emailclient/client/mailtrap"
	"{{ .serviceName }}/internal/emailclient/client/mandrill"
	"{{ .serviceName }}/internal/emailclient/client/salesforce"
	"{{ .serviceName }}/internal/emailclient/client/sendgrid"
	"{{ .serviceName }}/internal/emailclient/client/ses"
	"{{ .serviceName }}/internal/emailclient/client/smtp"
	"{{ .serviceName }}/internal/emailclient/client/zoho"
	"{{ .serviceName }}/internal/emailclient/types"
)

// MustNewClient creates a new email client based on the client type
func MustNewClient(clientType types.ClientType, auth *types.EmailAuth) types.EmailClient {
	var client types.EmailClient

	switch clientType {
	case types.ActiveCampaignClient:
		client = activecampaign.MustNewClient(auth)
	case types.AdobeClient:
		client = adobe.MustNewClient(auth)
	case types.AWeberClient:
		client = aweber.MustNewClient(auth)
	// case types.BenchmarkClient:
	// 	client = benchmark.MustNewClient(auth)
	// case types.BluecoreClient:
	// 	client = bluecore.MustNewClient(auth)
	case types.BrevoClient:
		client = brevo.MustNewClient(auth)
	// case types.CampaignMonitorClient:
	// 	client = campaignmonitor.MustNewClient(auth)
	case types.ConstantContactClient:
		client = constantcontact.MustNewClient(auth)
	case types.ConvertKitClient:
		client = convertkit.MustNewClient(auth)
	// case types.CopperClient:
	// 	client = copper.MustNewClient(auth)
	// case types.DotdigitalClient:
	// 	client = dotdigital.MustNewClient(auth)
	case types.DripClient:
		client = drip.MustNewClient(auth)
	// case types.ElasticEmailClient:
	// 	client = elasticemail.MustNewClient(auth)
	// case types.EloquaClient:
	// 	client = eloqua.MustNewClient(auth)
	// case types.EmmaClient:
	// 	client = emma.MustNewClient(auth)
	// case types.FreshsalesClient:
	// 	client = freshsales.MustNewClient(auth)
	case types.GetResponseClient:
		client = getresponse.MustNewClient(auth)
	case types.GmailClient:
		client = gmail.MustNewClient(auth)
	// case types.GMassClient:
	// 	client = gmass.MustNewClient(auth)
	case types.HubSpotClient:
		client = hubspot.MustNewClient(auth)
	// case types.IContactClient:
	// 	client = icontact.MustNewClient(auth)
	// case types.KeapClient:
	// 	client = keap.MustNewClient(auth)
	case types.KlaviyoClient:
		client = klaviyo.MustNewClient(auth)
	case types.MailchimpClient:
		client = mailchimp.MustNewClient(auth)
	// case types.MailerLiteClient:
	// 	client = mailerlite.MustNewClient(auth)
	// case types.MailerSendClient:
	// 	client = mailersend.MustNewClient(auth)
	case types.MailgunClient:
		client = mailgun.MustNewClient(auth)
	case types.MailjetClient:
		client = mailjet.MustNewClient(auth)
	case types.MailtrapClient:
		client = mailtrap.MustNewClient(auth)
	case types.MandrillClient:
		client = mandrill.MustNewClient(auth)
	// case types.MoosendClient:
	// 	client = moosend.MustNewClient(auth)
	// case types.NimbleClient:
	// 	client = nimble.MustNewClient(auth)
	// case types.OmnisendClient:
	// 	client = omnisend.MustNewClient(auth)
	// case types.OntraportClient:
	// 	client = ontraport.MustNewClient(auth)
	// case types.PabblyClient:
	// 	client = pabbly.MustNewClient(auth)
	// case types.PepipostClient:
	// 	client = pepipost.MustNewClient(auth)
	// case types.PipedriveClient:
	// 	client = pipedrive.MustNewClient(auth)
	// case types.PostmarkClient:
	// 	client = postmark.MustNewClient(auth)
	case types.SalesforceClient:
		client = salesforce.MustNewClient(auth)
	case types.SendGridClient:
		client = sendgrid.MustNewClient(auth)
	// case types.SendPulseClient:
	// 	client = sendpulse.MustNewClient(auth)
	case types.SESClient:
		client = ses.MustNewClient(auth)
	// case types.SharpSpringClient:
	// 	client = sharpspring.MustNewClient(auth)
	case types.SMTPClient:
		client = smtp.MustNewClient(auth)
	// case types.SparkPostClient:
	// 	client = sparkpost.MustNewClient(auth)
	// case types.VerticalResponseClient:
	// 	client = verticalresponse.MustNewClient(auth)
	case types.ZohoClient:
		client = zoho.MustNewClient(auth)
	default:
		fmt.Println("Unsupported email client type")
		return nil
	}

	return client
}
