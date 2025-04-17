# AWS configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_BUCKET_NAME=

# DigitalOcean configuration
DO_REGION=sfo3
DO_ACCESS_KEY_ID=
DO_SECRET_ACCESS_KEY=
DO_BUCKET_NAME=
DO_ENDPOINT=https://sfo3.digitaloceanspaces.com
DO_TOKEN=dop_v1_

# Email
EMAIL_FROM=no-reply@changeme.com
EMAIL_REPLY_TO=support@changeme.com
EMAIL_BASE_URL=https://mail.changeme.com
EMAIL_LIST_UNSUBSCRIBE="<mailto:unsubscribe@changeme.com?subject=unsubscribe>, <https://changeme.com/unsubscribe>"
EMAIL_PRIVACY_POLICY_URL=https://changeme.com/privacy
EMAIL_COMPANY_NAME=Company Name
EMAIL_COMPANY_ADDRESS="123 Main St, Provo, UT 84604"
EMAIL_COMPANY_PHONE="+1 (123) 456-7890"
EMAIL_SUPPORT_EMAIL=support@changeme.com

DSN="postgresql://postgres:CHANGE_ME@localhost:5432/{{ .serviceName }}?connect_timeout=180&sslmode=disable"
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_DB={{ .serviceName }}
POSTGRES_PORT=5432
POSTGRES_DEFAULT_PORT=5432
POSTGRES_HOST=postgres
POSTGRES_SSL_MODE=disable

# OpenAI configuration
OPENAI_ORG_ID=org-XXXXX
OPENAI_API_KEY=sk-XXXXXXX

ANTHROPIC_API_KEY=sk-ant-api03-XXXXXXX

# Temporal configuration
TEMPORAL_VERSION=1.24.2
TEMPORAL_ADMINTOOLS_VERSION=1.24.2-tctl-1.18.1-cli-0.13.0
TEMPORAL_UI_VERSION=2.26.2
POSTGRESQL_VERSION=16

VITE_API_BASE_URL=http://localhost:8888

