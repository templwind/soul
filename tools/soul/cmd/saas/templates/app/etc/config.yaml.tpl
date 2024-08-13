Name: {{.serviceName}}
Host: {{.host}}
Port: {{.port}}
DSN: ${DSN}
EnableWALMode: true
{{ .auth -}}
Site:
  Title: {{.serviceName}}
  LogoSvg: 
  LogoIconSvg: 
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
GPT:
  Endpoint: https://api.openai.com/v1/chat/completions
  APIKey: ${OPENAI_API_KEY}
  OrgID: ${OPENAI_ORG_ID}
  Model: gpt-4o
  DallEModel: dall-e-3
  DallEEndpoint: https://api.openai.com/v1/images/generations
