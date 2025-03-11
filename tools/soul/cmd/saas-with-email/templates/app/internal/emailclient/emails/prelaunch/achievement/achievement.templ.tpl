package achievement

import "{{ .serviceName }}/internal/emailclient/email"

templ Body(props *email.Props) {
	<h1 style="color: #264653; font-size: 28px; font-weight: 700;">Your Exclusive Prelaunch Access Awaits!</h1>
	if len(props.Lead) > 0 {
		<h2 style="color: #e76f51; font-size: 22px; font-weight: 600;">{ props.Lead }</h2>
	}
	<p style="font-size: 18px; color: #264653;">Congratulations! You're moments away from unlocking a world of innovation. Your golden ticket? This verification code:</p>
	<p style="text-align: center;"><strong style="color: #e76f51; font-size: 24px; background-color: #f8f9fa; padding: 10px 20px; border-radius: 4px;">{ props.Password }</strong></p>
	<p style="font-size: 18px;">Ready to step into the future? Click the button below to activate your account and join the revolution:</p>
	<p style="text-align: center;">
		<a href={ templ.SafeURL(props.ConfirmLink) } class="button">Activate Your VIP Access Now!</a>
	</p>
	<p style="font-size: 18px;">By activating, you're not just joining a platform; you're becoming part of an elite group of innovators shaping the future. During our exclusive prelaunch phase, you'll enjoy:</p>
	<ul style="color: #264653; font-size: 16px;">
		<li>First access to groundbreaking features</li>
		<li>Direct influence on our product roadmap</li>
		<li>Exclusive invites to virtual events with industry leaders</li>
	</ul>
	<p style="font-size: 18px;">But why keep this excitement to yourself? Spread the innovation! Use your unique referral link to invite fellow visionaries:</p>
	<div class="referral-box">
		<a href={ templ.SafeURL(props.ReferralLink) } class="referral-link">{ props.ReferralLink }</a>
	</div>
	<p style="font-size: 16px; font-style: italic; color: #666666; margin-top: 20px;">Remember, greatness doesn't wait. Activate your account now and let's make history together!</p>
}
