package config

import (
	{{.imports}}
)

type Config struct {
	webserver.WebServerConf
	db.DBConfig
	Nats        NatsConfig
	Redis       RedisConfig
	Environment string
	{{if not .isService}}
	EmbeddedFS  map[string]*embed.FS
	{{- end}}
	{{.auth -}}
	{{.jwtTrans -}}
	{{if not .isService}}
	Admin struct {
		AuthorizedDomains []string
	}
	Site struct {
		Title              string
		BaseURL            string
		LogoSvg            string
		LogoIconSvg        string
		CompanyName        string
		ContactEmail       string
		ContactAddress     string
		SupportEmail       string
		SupportPhoneNumber string
		Jurisdiction       string
		DaisyUITheme       string
		EmailDomains       []string
		Socials            Socials
	}
	Assets           Assets
	Menus            Menus
	{{- end}}
	TotalInstances   int
	GPT              GPT
{{if not .isService}}
	AllowedCountries map[string]bool `yaml:"AllowedCountries"`
	countryCodeList  map[string]string
	{{- end}}
	AWS              AWS
	{{if not .isService}}
	DigitalOcean     DigitalOcean
	Email            Email
	Stripe           Stripe
	{{- end}}
}

type NatsConfig struct {
	URL string
}

type RedisConfig struct {
	URL string
}

{{if not .isService}}
type Socials struct {
	X         string
	Youtube   string
	Instagram string
	Linkedin  string
	Facebook  string
	Slack     string
}
{{- end}}

type Anthropic struct {
	APIKey         string
	Model          string
	Endpoint       string
	RequestsPerMin int
}
{{if not .isService}}
type Stripe struct {
	SecretKey      string
	PublishableKey string
	WebhookSecret  string
}
{{end}}
{{if not .isService}}
type Email struct {
	From             string // Sender's email address
	ReplyTo          string // Address to receive replies, optional but recommended
	BaseURL          string // Base URL for links
	UnsubscribeURL   string // URL to handle unsubscriptions
	UnsubscribeText  string // Text for unsubscribe link
	ListUnsubscribe  string // List-Unsubscribe header
	PrivacyPolicyURL string // Link to your privacy policy
	CompanyInfo      struct {
		Name         string // Company name
		Address      string // Company address
		Phone        string // Company phone number
		SupportEmail string // Support email address
	}
}
{{end}}
type AWS struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
}
{{if not .isService}}
type DigitalOcean struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
	Endpoint        string
}
{{end}}
{{if not .isService}}
type Assets struct {
	Prelaunch struct {
		CSS []string
		JS  []string
	}
	Main struct {
		CSS []string
		JS  []string
	}
	App struct {
		CSS []string
		JS  []string
	}
	Admin struct {
		CSS []string
		JS  []string
	}
}
{{- end}}

type GPT struct {
	Endpoint       string
	APIKey         string
	OrgID          string
	Model          string
	DallEModel     string `yaml:"DallEModel,omitempty"`
	DallEEndpoint  string `yaml:"DallEEndpoint,omitempty"`
	TotalRPM       int
	MaxConcurrency int
}
{{if not .isService}}
func (c *Config) GetCountryCodeList() map[string]string {
	// Initialize countryCodeList
	c.countryCodeList = make(map[string]string)

	allowed := c.AllowedCountries
	allCountries := countries.All()

	// Filter and populate countryCodeList
	for _, country := range allCountries {
		alpha2 := country.Alpha2()
		if allowed[alpha2] {
			c.countryCodeList[alpha2] = country.Info().Name
		}
	}

	// Convert map to a slice for sorting
	sortedCountries := make([]struct {
		Code string
		Name string
	}, 0, len(c.countryCodeList))

	for code, name := range c.countryCodeList {
		sortedCountries = append(sortedCountries, struct {
			Code string
			Name string
		}{Code: code, Name: name})
	}

	// Sort the slice by country name
	sort.Slice(sortedCountries, func(i, j int) bool {
		return sortedCountries[i].Name < sortedCountries[j].Name
	})

	// Clear and repopulate the map in sorted order
	c.countryCodeList = make(map[string]string)
	for _, country := range sortedCountries {
		c.countryCodeList[country.Code] = country.Name
	}

	return c.countryCodeList
}
{{end}}
