Name: {{.serviceName}}
Host: {{.host}}
Port: {{.port}}
DSN: ${DSN}
EnableWALMode: true
Nats:
  URL: nats://nats:4222
Redis:
  URL: redis:6379
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
Admin:
  AuthorizedDomains:
    - localhost:8888
GPT:
  Endpoint: https://api.openai.com/v1/chat/completions
  APIKey: ${OPENAI_API_KEY}
  OrgID: ${OPENAI_ORG_ID}
  Model: gpt-4o-mini
  DallEModel: dall-e-3
  DallEEndpoint: https://api.openai.com/v1/images/generations
Anthropic:
  APIKey: ${ANTHROPIC_API_KEY}
  Model: davinci
  Endpoint: https://api.anthropic.com/v1/messages
  RequestsPerMin: 5
AWS:
  Region: ${AWS_REGION}
  AccessKeyID: ${AWS_ACCESS_KEY_ID}
  SecretAccessKey: ${AWS_SECRET_ACCESS_KEY}
  BucketName: ${AWS_BUCKET_NAME}
DigitalOcean:
  Region: ${DO_REGION}
  AccessKeyID: ${DO_ACCESS_KEY_ID}
  SecretAccessKey: ${DO_SECRET_ACCESS_KEY}
  BucketName: ${DO_BUCKET_NAME}
  Endpoint: ${DO_ENDPOINT}
