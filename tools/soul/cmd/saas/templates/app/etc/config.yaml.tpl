Name: {{.serviceName}}
Host: {{.host}}
Port: {{.port}}
DSN: ${DSN}
EnableWALMode: true
{{ .auth -}}
Email:
  From: ${EMAIL_FROM}
  ReplyTo: ${EMAIL_REPLY_TO} # Address to receive replies, optional but recommended
  BaseURL: ${EMAIL_BASE_URL}
  PrivacyPolicyURL: ${EMAIL_PRIVACY_POLICY_URL}
  CompanyInfo:
    Name: {{.serviceName}}
    Address: "123 Main St, Provo, UT 84604"
    Phone: "+1 (123) 456-7890"
    SupportEmail: support@{{.serviceName}}.com
{{if not .isService}}
Site:
  Title: {{.serviceName}}
  BaseURL: "http://localhost:8888"
  LogoSvg:
  LogoIconSvg:
  CompanyName: {{.serviceName}}
  ContactEmail: contact@{{.serviceName}}.com
  ContactAddress: 123 Main St, Anytown, UT 84604
  SupportEmail: support@{{.serviceName}}
  SupportPhoneNumber: +1 (123) 456-7890
  Jurisdiction: Utah, United States
  DaisyUITheme: light
  EmailDomains:
    - {{.serviceName}}.com
    - mail.{{.serviceName}}.com
    - {{.serviceName}}:8888
  Socials:
    X: "{{.serviceName}}"
    Youtube: "{{.serviceName}}"
    Instagram: "{{.serviceName}}"
    Linkedin: "{{.serviceName}}"
    Facebook: "{{.serviceName}}"
    Slack: "{{.serviceName}}"
Admin:
  AuthorizedDomains:
    - localhost:8888
Assets:
  Main:
    CSS:
      - /assets/css/main.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/js/main.js
  App:
    CSS:
      - /assets/css/app.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/js/app.js
  Admin:
    CSS:
      - /assets/css/admin.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/js/admin.js
{{- end}}
Pricing:
  Headline: Pricing
  SubHeadline: Save up to 30% on annual plans
  HighlightedIdx: 2
  Plans:
    - ID: free
      Name: Free
      Headline: For your personal {{.serviceName}}
      SubHeadline: Share your knowledge with the world
      Description: "Key features:"
      MonthlyPrice: 0
      AnnualPrice: 0
      PriceHelp: Free, forever
      Features:
        - One lead magnet
        - One landing page
        - Unlimited "thank you" links
        - 25 downloads per month
        - Basic analytics
        - "Maximum file size: 5MB"
      ButtonText: Join for free
      URL: /auth/register/free
      Notes:
        - "Downloads do not accumulate—unused downloads reset at the beginning of each month."
      Credits: 25
      CreditsTitle: downloads
    - ID: aspiring
      Name: Aspiring
      Headline: For creators just starting out
      SubHeadline: Kickstart your sharing journey
      Description: "Key features:"
      MonthlyPrice: 9
      AnnualPrice: 90 # Save with 2 months free on annual plans
      PriceHelp: "Save $18 annually"
      Features:
        - 100 downloads per month
        - Basic integrations
        - Access to basic analytics
      ButtonText: Get Aspiring
      URL: /onboarding/choose-plan?plan_id=aspiring
      Notes:
        - "Downloads do not accumulate—unused downloads reset at the beginning of each month."
      Credits: 100
      CreditsTitle: downloads
      Overage:
        PricePerDownload: 0.08
        Description: "8¢ per additional download beyond 100 downloads"
      Bundles:
        - Name: 500 downloads
          Price: 5
          Qty: 500
          Description: Additional 500 downloads (max 5MB each)
        - Name: 1,000 downloads
          Price: 10
          Qty: 1000
          Description: Additional 1,000 downloads (max 5MB each)
      # Bonuses:
      #   - Name: "Bonus 1"
      #     RetailPrice: 19.99
      #     Description: "Access to a special creator's toolkit."
      #   - Name: "Bonus 2"
      #     RetailPrice: 49.99
      #     Description: "Exclusive invitation to a live Q&A with top influencers."

    - ID: dominating
      Name: Dominating
      Headline: For growing creators
      SubHeadline: Expand your reach with advanced features
      Description: "Key features:"
      MonthlyPrice: 39
      AnnualPrice: 290 # Save with 2 months free on annual plans
      PriceHelp: "Save $58 annually"
      Features:
        - 1,000 downloads per month
        - Advanced integrations
        - API access
        - Priority support
        - Access to advanced analytics
      ButtonText: Get Dominating
      URL: /onboarding/choose-plan?plan_id=dominating
      Notes:
        - "Downloads do not accumulate—unused downloads reset at the beginning of each month."
      Credits: 1000
      CreditsTitle: downloads
      Overage:
        PricePerDownload: 0.05
        Description: "5¢ per additional download beyond 500 downloads"
      Bundles:
        - Name: 5,000 downloads
          Price: 35
          Qty: 5000
          Description: Additional 5,000 downloads (max 20MB each)
        - Name: 10,000 downloads
          Price: 60
          Qty: 10000
          Description: Additional 10,000 downloads (max 20MB each)
      # Bonuses:
      #   - Name: "Bonus 1"
      #     RetailPrice: 99.99
      #     Description: "Advanced branding kit and analytics guides."
      #   - Name: "Bonus 2"
      #     RetailPrice: 149.99
      #     Description: "VIP access to new feature previews and webinars."
GPT:
  Endpoint: https://api.openai.com/v1/chat/completions
  APIKey: ${OPENAI_API_KEY}
  OrgID: ${OPENAI_ORG_ID}
  Model: gpt-4o
  DallEModel: dall-e-3
  DallEEndpoint: https://api.openai.com/v1/images/generations
Anthropic:
  APIKey: $ANTHROPIC_API_KEY}
  Model: davinci
  Endpoint: https://api.anthropic.com/v1/messages
  RequestsPerMin: 5
AWS:
  Region: ${AWS_REGION}
  AccessKeyID: ${AWS_ACCESS_KEY_ID}
  SecretAccessKey: $AWS_SECRET_ACCESS_KEY}
  BucketName: ${AWS_BUCKET_NAME}
DigitalOcean:
  Region: ${DO_REGION}
  AccessKeyID: ${DO_ACCESS_KEY_ID}
  SecretAccessKey: $DO_SECRET_ACCESS_KEY}
  BucketName: ${DO_BUCKET_NAME}
  Endpoint: ${DO_ENDPOINT}
Settings:
  AccountSettings:
    - category: billing
      order: 1
      items:
        - key: "stripe-api-key"
          value: ""
          name: "Stripe API Key"
          description: "The API key used to connect to Stripe."
          required: true
          disabled: false
          kind: "password"
          scope: "account"
          order: 1

        - key: "paypal-client-id"
          value: ""
          name: "PayPal Client ID"
          description: "The Client ID used to connect to PayPal."
          required: false
          disabled: false
          kind: "text"
          scope: "account"
          order: 2

        - key: "billing-overdue-notification"
          value: "true"
          name: "Billing Overdue Notification"
          description: "Send notifications when billing becomes overdue."
          required: true
          disabled: false
          kind: "boolean"
          scope: "account"
          order: 3

        - key: "low-credit-notification-threshold"
          value: "10"
          name: "Low Credit Notification Threshold"
          description: "The threshold at which to notify users when their credits are running low."
          required: false
          disabled: false
          kind: "number"
          scope: "account"
          order: 4

        - key: "credit-usage-summary"
          value: "monthly"
          name: "Credit Usage Summary Frequency"
          description: "How often to send credit usage summaries to users."
          required: false
          disabled: false
          kind: "select"
          options:
            - "daily"
            - "weekly"
            - "monthly"
          scope: "account"
          order: 5

    - category: email
      order: 2
      items:
        - key: "email-smtp-server"
          value: ""
          name: "SMTP Server"
          description: "The SMTP server used for sending emails."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 6

        - key: "email-smtp-port"
          value: "587"
          name: "SMTP Port"
          description: "The port number for the SMTP server."
          required: true
          disabled: false
          kind: "number"
          scope: "account"
          order: 7

        - key: "email-support-address"
          value: "support@{{.serviceName}}.com"
          name: "Support Email Address"
          description: "The email address for {{.serviceName}} support."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 8

    - category: storage
      order: 3
      items:
        - key: "default-storage-limit"
          value: "5GB"
          name: "Default Storage Limit"
          description: "Default storage space available to free-tier users."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 9

        - key: "max-file-size-upload"
          value: "5MB"
          name: "Max File Size Upload"
          description: "The maximum file size allowed for uploads in {{.serviceName}}."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 10

    - category: integrations
      order: 4
      items:
        - key: "integration-google-analytics"
          value: ""
          name: "Google Analytics Tracking ID"
          description: "Tracking ID for integrating Google Analytics."
          required: false
          disabled: false
          kind: "text"
          scope: "account"
          order: 11

        - key: "integration-facebook-pixel"
          value: ""
          name: "Facebook Pixel ID"
          description: "Facebook Pixel ID for tracking activity."
          required: false
          disabled: false
          kind: "text"
          scope: "account"
          order: 12

    - category: legal
      order: 5
      items:
        - key: "privacy-policy-url"
          value: "https://{{.serviceName}}.com/privacy"
          name: "Privacy Policy URL"
          description: "URL to {{.serviceName}}'s privacy policy."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 13

        - key: "terms-of-service-url"
          value: "https://{{.serviceName}}.com/terms"
          name: "Terms of Service URL"
          description: "URL to {{.serviceName}}'s terms of service."
          required: true
          disabled: false
          kind: "text"
          scope: "account"
          order: 14

    - category: notifications
      order: 6
      items:
        - key: "notify-on-billing-issue"
          value: "true"
          name: "Notify on Billing Issue"
          description: "Send notifications to admin group members when there is a billing issue."
          required: false
          disabled: true
          kind: "boolean"
          scope: "account"
          order: 15

        - key: "notify-on-new-user-signup"
          value: "false"
          name: "Notify on New User Signup"
          description: "Send a notification to admin group when a new user signs up."
          required: false
          disabled: false
          kind: "boolean"
          scope: "account"
          order: 16

        - key: "notify-on-credit-usage-threshold"
          value: "false"
          name: "Notify on Credit Usage Threshold"
          description: "Notify admin group members when a user's credit usage hits the set threshold."
          required: false
          disabled: false
          kind: "boolean"
          scope: "account"
          order: 17

  UserSettings:
    - category: preferences
      order: 1
      items:
        - key: "theme-color"
          value: "light"
          name: "Theme Color"
          description: "Preferred theme color of the dashboard."
          required: false
          disabled: true
          kind: "select"
          options:
            - "light"
            - "dark"
          scope: "user"
          order: 1

        - key: "default-language"
          value: "en"
          name: "Default Language"
          description: "Preferred language for the application."
          required: false
          disabled: true
          kind: "select"
          options:
            - "en"
            - "es"
            - "fr"
            - "de"
          scope: "user"
          order: 2

    - category: notifications
      order: 2
      items:
        - key: "daily-summary-email"
          value: "true"
          name: "Daily Summary Email"
          description: "Receive a daily summary of your {{.serviceName}} activity."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 1

        - key: "lead-magnet-notifications"
          value: "true"
          name: "Lead Magnet Notifications"
          description: "Receive notifications when someone downloads your lead magnet."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 2

        - key: "security-alerts"
          value: "true"
          name: "Security Alerts"
          description: "Receive notifications about any unusual login attempts or changes to your account."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 3

        - key: "new-feature-announcement"
          value: "false"
          name: "New Feature Announcements"
          description: "Receive notifications when new features are added to {{.serviceName}}."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 4

        - key: "new-comment-notification"
          value: "false"
          name: "New Comment Notification"
          description: "Receive a notification when someone comments on your content."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 5

        - key: "weekly-activity-summary"
          value: "true"
          name: "Weekly Activity Summary"
          description: "Receive a summary of your weekly activity on {{.serviceName}}."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 6

        - key: "special-promotions"
          value: "true"
          name: "Special Promotions"
          description: "Receive special promotional offers and discounts from {{.serviceName}}."
          required: false
          disabled: false
          kind: "boolean"
          scope: "user"
          order: 7

    - category: billing
      order: 3
      items:
        - key: "preferred-payment-method"
          value: "credit_card"
          name: "Preferred Payment Method"
          description: "Select the preferred payment method for purchases."
          required: false
          disabled: true
          kind: "select"
          options:
            - "credit_card"
            - "paypal"
          scope: "user"
          order: 1

        - key: "payment-failure-alert"
          value: "true"
          name: "Payment Failure Alert"
          description: "Receive notifications if a payment fails."
          required: false
          disabled: true
          kind: "boolean"
          scope: "user"
          order: 2

        - key: "subscription-renewal-reminder"
          value: "true"
          name: "Subscription Renewal Reminder"
          description: "Get reminders before your subscription is due for renewal."
          required: false
          disabled: true
          kind: "boolean"
          scope: "user"
          order: 3

        - key: "credit-usage-alert"
          value: "true"
          name: "Credit Usage Alert"
          description: "Receive a notification when your credit usage reaches a certain threshold."
          required: false
          disabled: true
          kind: "boolean"
          scope: "user"
          order: 4

    - category: security
      order: 4
      items:
        - key: "two-factor-auth"
          value: "false"
          name: "Two-Factor Authentication"
          description: "Enable two-factor authentication for added security."
          required: false
          disabled: true
          kind: "boolean"
          scope: "user"
          order: 1

    - category: privacy
      order: 5
      items:
        - key: "profile-visibility"
          value: "public"
          name: "Profile Visibility"
          description: "Controls the visibility of the user profile."
          required: false
          disabled: true
          kind: "select"
          options:
            - "public"
            - "private"
          scope: "user"
          order: 1