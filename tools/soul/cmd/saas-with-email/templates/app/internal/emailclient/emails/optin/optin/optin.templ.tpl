package optin

import "{{ .serviceName }}/internal/emailclient/email"

templ Body(props *email.Props) {
	<h1 style="color: #264653; font-size: 28px; font-weight: 700;">Here's Your Download</h1>
	if len(props.Lead) > 0 {
		<h2 style="color: #e76f51; font-size: 22px; font-weight: 600;">{ props.Lead }</h2>
	}
	<p style="font-size: 18px; color: #264653;">Thanks for your interest. Your download is ready.</p>
	<p style="text-align: center;">
		<a href={ templ.SafeURL(props.DownloadLink) } class="button">Download Now</a>
	</p>
	<p style="font-size: 16px; color: #666666; margin-top: 20px;">Enjoy!</p>
}
