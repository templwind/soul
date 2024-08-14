# AWS configuration
AWS_REGION=
AWS_ACCOUNT_ID=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# DB configuration
{{- if eq .dbType "sqlite" }}
DSN=sqlite://db/data/{{.dsnName}}.db
{{ else if eq .dbType "mysql" }}
DSN=mysql://db/data/{{.dsnName}}.db
{{ else if eq .dbType "postgres" }}
DSN=postgresql://postgres:CHANGE_ME@localhost:5432/{{.serviceName}}?connect_timeout=180&sslmode=disable
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_DB={{.serviceName}}
POSTGRES_PORT=5432
POSTGRES_DEFAULT_PORT=5432
POSTGRES_DEV_HOST=localhost
POSTGRES_DEV_PORT=5432
POSTGRES_HOST=postgres
POSTGRES_SSL_MODE=disable
{{- end }}

# DigitalOcean configuration
DO_REGION=sfo3
DO_ACCESS_KEY_ID=DOXXXX
DO_SECRET_ACCESS_KEY=XXXX
DO_BUCKET_NAME=goshare
DO_ENDPOINT=https://XXXX.sfo3.digitaloceanspaces.com
***REMOVED***=dop_v1_XXXX


# OpenAI configuration
OPENAI_ORG_ID=
OPENAI_API_KEY=

# Temporal configuration
TEMPORAL_VERSION=1.24.2
TEMPORAL_ADMINTOOLS_VERSION=1.24.2-tctl-1.18.1-cli-0.13.0
TEMPORAL_UI_VERSION=2.26.2
POSTGRESQL_VERSION=16

# XO configuration
XO_INCLUDES="accounts \
user_types \
users \
user_accounts \
products \
subscriptions \
payment_methods \
invoices \
payment_attempts \
oauth_states \
posts \
comments \
tags \
reviews \
audit_logs \
roles \
permissions \
role_permissions \
user_roles \
notifications \
settings \
attachments"
