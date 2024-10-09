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
DO_BUCKET_NAME=XXXX
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
XO_INCLUDES=""
# XO_INCLUDES="accounts \
# user_types \
# users \
# user_accounts \
# products \
# subscriptions \
# payment_methods \
# invoices \
# payment_attempts \
# oauth_states \
# posts \
# comments \
# tags \
# reviews \
# audit_logs \
# roles \
# permissions \
# role_permissions \
# user_roles \
# notifications \
# settings \
# email_senders \
# niches \
# ai_prompts \
# optin_emails \
# funnels \
# funnel_pages \
# split_tests \
# variants \
# funnel_page_variants \
# page_views \
# conversions \
# daily_funnel_summary \
# component_tests \
# email_types \
# email_campaigns \
# email_templates \
# email_recipients \
# email_sends \
# email_status_history \
# email_links \
# email_clicks \
# email_opens \
# email_metrics \
# email_unsubscribes \
# referrals \
# referral_summary \
# daily_referral_summary \
# achievements \
# user_achievements \
# leaderboards \
# daily_engagement \
# user_points \
# user_profiles \
# lead_magnet_traffic \
# lead_magnet_daily_stats \
# lead_magnet_overall_stats \
# user_profile_traffic \
# user_profile_daily_stats \
# user_profile_overall_stats \
# endorsements \
# testimonials \
# files \
# buckets \
# downloads"
