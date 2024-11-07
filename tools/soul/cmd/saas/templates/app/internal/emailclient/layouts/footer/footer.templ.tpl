package footer

import "time"

templ tpl(props *Props) {
	<div class="footer">
		<p>
			{ props.Message }
		</p>
		<p><unsubscribe>Unsubscribe</unsubscribe> | Sent by <span class="footer-company">{ props.CompanyName }</span></p>
		<p>{ props.Address1 } • { props.City }, { props.State } • { props.Zip } • { props.Country }</p>
		<div class="footer-links">
			<a href={ templ.SafeURL(props.PrivacyURL) }>Privacy Policy</a> | 
			<a href={ templ.SafeURL(props.TermsURL) }>Terms of Service</a>
		</div>
		<p class="footer-copyright">&copy; { time.Now().Format("2006") } { props.CompanyName }. All rights reserved.</p>
	</div>
}
