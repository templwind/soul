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
      - /assets/main/css/styles.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/main/js/main.js
  App:
    CSS:
      - /assets/app/css/styles.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/app/js/app.js
  Admin:
    CSS:
      - /assets/admin/css/styles.css
    JS:
      - https://unpkg.com/htmx.org@2.0.0
      - /assets/admin/js/admin.js
GPT:
  Endpoint: https://api.openai.com/v1/chat/completions
  APIKey: ${OPENAI_API_KEY}
  OrgID: ${OPENAI_ORG_ID}
  Model: gpt-4o
  DallEModel: dall-e-3
  DallEEndpoint: https://api.openai.com/v1/images/generations
Menus:
  signin:
    - URL: /auth/login
      Title: Sign in
      HxDisable: true
  register:
    - URL: /auth/register
      Title: Get started today
      HxDisable: true
  main:
    - URL: /features
      Title: Features
    - URL: /pricing
      Title: Pricing
  footer:
    - URL: /solutions
      Title: Solutions
      Children:
        - URL: /solutions/page1
          Title: Solution 1
    - URL: /support
      Title: Support
      Children:
        - URL: /contact
          Title: Contact
        - URL: /pricing
          Title: Pricing
        - URL: /features
          Title: Features
        - URL: /faq
          Title: FAQ
    - URL: /legal
      Title: Legal
      Children:
        - URL: /legal/terms
          Title: Terms of Service
        - URL: /legal/privacy
          Title: Privacy Policy
    - URL: /company
      Title: Company
      Children:
        - URL: /about
          Title: About
        - URL: /blog
          Title: Blog
  rail:
    - Title: Dashboard
      URL: /app
      Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M8 6c0-2.21 1.79-4 4-4s4 1.79 4 4s-1.79 4-4 4s-4-1.79-4-4m9 16h1c1.1 0 2-.9 2-2v-4.78c0-1.12-.61-2.15-1.61-2.66c-.43-.22-.89-.43-1.39-.62zm-4.66-5L15 11.33c-.93-.21-1.93-.33-3-.33c-2.53 0-4.71.7-6.39 1.56A2.97 2.97 0 0 0 4 15.22V22h2.34c-.22-.45-.34-.96-.34-1.5C6 18.57 7.57 17 9.5 17zM10 22l1.41-3H9.5c-.83 0-1.5.67-1.5 1.5S8.67 22 9.5 22z"/></svg>
      # Children:
      #   - Title: 
      #     URL: /app/something
      #     Icon: 
    # - Title: Feature 1
    #   URL: /app/feature1
    #   Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M8 6c0-2.21 1.79-4 4-4s4 1.79 4 4s-1.79 4-4 4s-4-1.79-4-4m9 16h1c1.1 0 2-.9 2-2v-4.78c0-1.12-.61-2.15-1.61-2.66c-.43-.22-.89-.43-1.39-.62zm-4.66-5L15 11.33c-.93-.21-1.93-.33-3-.33c-2.53 0-4.71.7-6.39 1.56A2.97 2.97 0 0 0 4 15.22V22h2.34c-.22-.45-.34-.96-.34-1.5C6 18.57 7.57 17 9.5 17zM10 22l1.41-3H9.5c-.83 0-1.5.67-1.5 1.5S8.67 22 9.5 22z"/></svg>
    #   Children:
    #     - Title: 
    #       URL: /app/something
    #       Icon: 
    - Title: Settings
      URL: /app/settings
      Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M12 15.5A3.5 3.5 0 0 1 8.5 12A3.5 3.5 0 0 1 12 8.5a3.5 3.5 0 0 1 3.5 3.5a3.5 3.5 0 0 1-3.5 3.5m7.43-2.53c.04-.32.07-.64.07-.97s-.03-.66-.07-1l2.11-1.63c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.31-.61-.22l-2.49 1c-.52-.39-1.06-.73-1.69-.98l-.37-2.65A.506.506 0 0 0 14 2h-4c-.25 0-.46.18-.5.42l-.37 2.65c-.63.25-1.17.59-1.69.98l-2.49-1c-.22-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64L4.57 11c-.04.34-.07.67-.07 1s.03.65.07.97l-2.11 1.66c-.19.15-.25.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1.01c.52.4 1.06.74 1.69.99l.37 2.65c.04.24.25.42.5.42h4c.25 0 .46-.18.5-.42l.37-2.65c.63-.26 1.17-.59 1.69-.99l2.49 1.01c.22.08.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64z"/></svg>
      IsAtEnd: true
      Children:
        - Title: Settings
          Lead: Update your account settings
          URL: /app/settings
          Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M12 15.5A3.5 3.5 0 0 1 8.5 12A3.5 3.5 0 0 1 12 8.5a3.5 3.5 0 0 1 3.5 3.5a3.5 3.5 0 0 1-3.5 3.5m7.43-2.53c.04-.32.07-.64.07-.97s-.03-.66-.07-1l2.11-1.63c.19-.15.24-.42.12-.64l-2-3.46c-.12-.22-.39-.31-.61-.22l-2.49 1c-.52-.39-1.06-.73-1.69-.98l-.37-2.65A.506.506 0 0 0 14 2h-4c-.25 0-.46.18-.5.42l-.37 2.65c-.63.25-1.17.59-1.69.98l-2.49-1c-.22-.09-.49 0-.61.22l-2 3.46c-.13.22-.07.49.12.64L4.57 11c-.04.34-.07.67-.07 1s.03.65.07.97l-2.11 1.66c-.19.15-.25.42-.12.64l2 3.46c.12.22.39.3.61.22l2.49-1.01c.52.4 1.06.74 1.69.99l.37 2.65c.04.24.25.42.5.42h4c.25 0 .46-.18.5-.42l.37-2.65c.63-.26 1.17-.59 1.69-.99l2.49 1.01c.22.08.49 0 .61-.22l2-3.46c.12-.22.07-.49-.12-.64z"/></svg>
        - Title: Account
          URL: /app/settings/account
          Lead: Update your account details
          Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M6 17c0-2 4-3.1 6-3.1s6 1.1 6 3.1v1H6m9-9a3 3 0 0 1-3 3a3 3 0 0 1-3-3a3 3 0 0 1 3-3a3 3 0 0 1 3 3M3 5v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2"/></svg>
        - Title: Billing
          Lead: Manage your billing details
          URL: /app/settings/billing
          Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M7 15h2c0 1.08 1.37 2 3 2s3-.92 3-2c0-1.1-1.04-1.5-3.24-2.03C9.64 12.44 7 11.78 7 9c0-1.79 1.47-3.31 3.5-3.82V3h3v2.18C15.53 5.69 17 7.21 17 9h-2c0-1.08-1.37-2-3-2s-3 .92-3 2c0 1.1 1.04 1.5 3.24 2.03C14.36 11.56 17 12.22 17 15c0 1.79-1.47 3.31-3.5 3.82V21h-3v-2.18C8.47 18.31 7 16.79 7 15"/></svg>
        - Title: Switch Account
          Lead: Switch to another account
          URL: /app/settings/switch-account
          Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="m21 9l-4-4v3h-7v2h7v3M7 11l-4 4l4 4v-3h7v-2H7z"/></svg>
        - Title: Logout
          URL: /auth/logout
          Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="m17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5M4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4z"/></svg>
          HxDisable: true
          IsAtEnd: true
  mobileFooter:
    - Title: Encounters
      MobileTitle: Encounters
      InMobile: true
      URL: /app/encounters/list
      Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M8 6c0-2.21 1.79-4 4-4s4 1.79 4 4s-1.79 4-4 4s-4-1.79-4-4m9 16h1c1.1 0 2-.9 2-2v-4.78c0-1.12-.61-2.15-1.61-2.66c-.43-.22-.89-.43-1.39-.62zm-4.66-5L15 11.33c-.93-.21-1.93-.33-3-.33c-2.53 0-4.71.7-6.39 1.56A2.97 2.97 0 0 0 4 15.22V22h2.34c-.22-.45-.34-.96-.34-1.5C6 18.57 7.57 17 9.5 17zM10 22l1.41-3H9.5c-.83 0-1.5.67-1.5 1.5S8.67 22 9.5 22z"/></svg>
    - Title: New Encounter
      MobileTitle: New
      InMobile: true
      URL: /app/encounters
      Icon: <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M8 6c0-2.21 1.79-4 4-4s4 1.79 4 4s-1.79 4-4 4s-4-1.79-4-4m9 16h1c1.1 0 2-.9 2-2v-4.78c0-1.12-.61-2.15-1.61-2.66c-.43-.22-.89-.43-1.39-.62zm-4.66-5L15 11.33c-.93-.21-1.93-.33-3-.33c-2.53 0-4.71.7-6.39 1.56A2.97 2.97 0 0 0 4 15.22V22h2.34c-.22-.45-.34-.96-.34-1.5C6 18.57 7.57 17 9.5 17zM10 22l1.41-3H9.5c-.83 0-1.5.67-1.5 1.5S8.67 22 9.5 22z"/></svg>
AllowedCountries:
  US: true # United States
  CA: true # Canada
  AU: true # Australia
  NZ: true # New Zealand
  AS: true # American Samoa
  GU: true # Guam
  MP: true # Northern Mariana Islands
  VI: true # U.S. Virgin Islands
  BS: true # Bahamas
  GB: true # United Kingdom
  IE: true # Ireland
  DE: true # Germany
  FR: true # France
  IT: true # Italy
  ES: true # Spain
  NL: true # Netherlands
  BE: true # Belgium
  DK: true # Denmark
  SE: true # Sweden
  FI: true # Finland
  NO: true # Norway
  CH: true # Switzerland
  AT: true # Austria
  LU: true # Luxembourg
  PT: true # Portugal
  IS: true # Iceland
  MT: true # Malta
Pricing:
  Headline: Your Headline Here
  SubHeadline: Your Subheadline Here
  HighlightedIdx: 1
  Plans:
    - Name: Trial
      Price: Free
      Description: Test drive
      Features:
        - Awesome benefit 1
        - Awesome benefit 2
        - Awesome benefit 3
      ButtonText: Try For Free
      URL: /auth/register/trial
    - Name: Individual
      Price: "99 / mo"
      Description: Growing business
      Features:
        - Awesome benefit 4
        - Awesome benefit 5
        - Awesome benefit 6
      ButtonText: Try For Free
      URL: /auth/register/individual
    - Name: Group
      Price: Custom
      Description: Enterprise solution
      Features:
        - Awesome benefit 7
        - Awesome benefit 8
        - Awesome benefit 9
      ButtonText: Contact Us
      URL: /contact
