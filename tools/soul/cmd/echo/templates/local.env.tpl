# AWS configuration
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
AWS_REGION=us-east-1

# Data source name
DSN=sqlite://db/data/{{.dsnName}}.db

# XO_INCLUDES
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

# OpenAI
OPENAI_ORG_ID=<your-org-id>
OPENAI_API_KEY=<your-api-key>