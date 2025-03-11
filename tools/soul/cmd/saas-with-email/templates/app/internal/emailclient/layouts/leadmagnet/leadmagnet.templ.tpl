package leadmagnet

import "{{ .serviceName }}/internal/emailclient/email"

templ Template(props *email.Props) {
	<!DOCTYPE html>
	<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office">
		<head>
			<meta charset="UTF-8"/>
			<meta name="viewport" content="width=device-width,initial-scale=1"/>
			<meta name="x-apple-disable-message-reformatting"/>
			<title></title>
			<!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
			<style>
    body, table, td, div, p {font-family: Arial, sans-serif; font-size: 16px;}
    body {margin: 0; padding: 0; background-color: #f8f9fa;}
    .container {max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 20px;}
    .button {
      background-color: #2a9d8f;
      color: #ffffff !important;
      padding: 14px 28px;
      text-align: center;
      text-decoration: none;
      display: inline-block;
      font-size: 18px;
      font-weight: 600;
      margin: 4px 2px;
      cursor: pointer;
      border-radius: 8px;
    }
    .referral-box {
      border: 2px solid #e76f51;
      border-radius: 8px;
      padding: 12px;
      margin-top: 16px;
    }
    .referral-link {
      color: #e76f51;
      text-decoration: none;
      font-weight: 600;
	  text-align: center;
    }
    .preheader {display: none; font-size: 1px; color: #ffffff; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden;}
    /* Logo component styles */
    .logo {display: flex; flex-wrap: wrap; justify-content: center;}
    .text-accent {color: #e9c46a;}
    .text-secondary {color: #e76f51;}
    .text-4xl {font-size: 2.25rem;}
    .font-black {font-weight: 900;}
    .-ml-1 {margin-left: -0.25rem;}
    @media only screen and (max-width: 600px) {
      .container {width: 100% !important; padding: 10px !important;}
      .button {width: 100% !important; display: block !important; box-sizing: border-box;}
    }
	/* Footer styles */
	.footer {
	padding: 24px 8px;
	margin-top: 40px;
	border-top: 1px solid #e0e0e0;
	font-size: 12px;
	color: #666666;
	line-height: 1.5;
	background-color: #f8f9fa;
	text-align: center;
	}

	.footer p {
	margin: 8px 0;
	text-align: center;
	font-size: 12px;
	}

	.footer a {
	color: #2a9d8f;
	text-decoration: none;
	transition: color 0.3s ease;
	font-size: 12px;
	}

	.footer a:hover {
	color: #264653;
	text-decoration: underline;
	font-size: 12px;
	}

	.footer-links {
	margin: 12px 0;
	font-size: 12px;
	}

	.footer-links a {
	margin: 0 8px;
	font-size: 12px;
	}

	.footer-company {
	font-weight: bold;
	color: #264653;
	font-size: 12px;
	}

	.footer-copyright {
	margin-top: 16px;
	font-size: 12px;
	color: #999999;
	}
  </style>
		</head>
		<body>
			<!-- Email preview text -->
			<div class="preheader">{ props.PreviewText } &zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;</div>
			<div class="container">
				<!-- Logo component -->
				// <div style="margin-bottom: 20px;">
				// 	@logo.New(
				// 		logo.WithFancyBrandName(props.BrandName),
				// 		logo.WithColors("text-accent", "text-secondary", "text-accent"),
				// 	)
				// </div>
				@props.BodyComponent
				[footer]
			</div>
		</body>
	</html>
}
