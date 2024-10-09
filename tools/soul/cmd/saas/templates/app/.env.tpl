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
***REMOVED***=dop_v1_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

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
OPENAI_ORG_ID=org-XXXXXXXXXXXXXXXXXXXXXXXX
OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

ANTHROPIC_API_KEY=sk-ant-api03-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# Temporal configuration
TEMPORAL_VERSION=1.24.2
TEMPORAL_ADMINTOOLS_VERSION=1.24.2-tctl-1.18.1-cli-0.13.0
TEMPORAL_UI_VERSION=2.26.2
POSTGRESQL_VERSION=16

VITE_API_BASE_URL=http://localhost:8888

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
attachments \
email_senders \
niches \
ai_prompts \
lead_magnets \
lead_magnet_types \
prompt_lead_magnet_links \
lead_magnet_content \
optin_emails \
funnels \
funnel_pages \
split_tests \
variants \
funnel_page_variants \
page_views \
conversions \
daily_funnel_summary \
component_tests \
email_types \
email_campaigns \
email_templates \
email_recipients \
email_sends \
email_status_history \
email_links \
email_clicks \
email_opens \
email_metrics \
email_unsubscribes \
referrals \
referral_summary \
daily_referral_summary \
achievements \
user_achievements \
leaderboards \
daily_engagement \
user_points \
user_profiles \
lead_magnet_traffic \
lead_magnet_daily_stats \
lead_magnet_overall_stats \
user_profile_traffic \
user_profile_daily_stats \
user_profile_overall_stats \
endorsements \
testimonials \
files \
buckets \
downloads"
