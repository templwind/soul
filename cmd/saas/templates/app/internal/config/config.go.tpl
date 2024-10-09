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
	Pricing          Pricing
	TotalInstances   int
	GPT              GPT
	AllowedCountries map[string]bool `yaml:"AllowedCountries"`
	countryCodeList  map[string]string
	AWS              AWS
	DigitalOcean     DigitalOcean
	Email            Email
	Stripe           Stripe
	Settings         settings.Settings
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

type Stripe struct {
	SecretKey      string
	PublishableKey string
	WebhookSecret  string
}

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

type AWS struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
}

type DigitalOcean struct {
	Region          string
	AccessKeyID     string
	SecretAccessKey string
	BucketName      string
	Endpoint        string
}

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

// Pricing defines the pricing plans and their features
type Pricing struct {
	Plans          []Plan // List of pricing plans
	HighlightedIdx int    // Index of the highlighted plan
	FAQ            []FAQ  // List of FAQ items
}

// FAQ defines the structure for Frequently Asked Questions
type FAQ struct {
	Question string   // The question being asked
	Answer   string   // The answer to the question
	Example  *Example // Optional example for the FAQ (e.g., pricing calculation)
}

// Example defines a structure to show an optional pricing example
type Example struct {
	Description  string  // Short description of the example
	PlanPrice    int     // Base plan price
	OverageQty   int     // Quantity of overages (extra downloads)
	OverageCost  float64 // Cost per extra download
	FormatString string  // Format string for the example
}

// Plan defines the structure for each pricing plan
type Plan struct {
	ID           string   // Plan ID (e.g., free, aspiring, dominating)
	Name         string   // Plan name (e.g., Free, Aspiring, Dominating)
	MonthlyPrice int      // Monthly price for the plan
	AnnualPrice  int      // Annual price for the plan (with discount)
	PriceHelp    string   // Pricing help or discount information
	Headline     string   // Plan headline
	SubHeadline  string   // Plan subheadline
	Description  string   // Short description of the plan
	Features     []string // List of plan features
	ButtonText   string   // Text for the plan selection button
	URL          string   // URL for the plan registration
	Bundles      []Bundle // Additional bundles for more downloads
	Overage      Overage  // Overage pricing information
	Notes        []string // Additional notes for the plan
	Credits      int      // Number of credits included in the plan
	CreditsTitle string   // Title of the credits (e.g., downloads, uploads, etc.)
	Bonuses      []Bonus  // List of bonuses offered with the plan
}

// Bundle defines the structure for additional bundles available within a plan
type Bundle struct {
	Name        string // Bundle name (e.g., 500 downloads)
	Price       int    // Price for the bundle
	Qty         int    // Number of downloads included in the bundle
	Description string // Description of the bundle
}

// Overage defines the structure for overage pricing per download
type Overage struct {
	PricePerDownload float64 // Price per additional download beyond plan limit
	Description      string  // Description of the overage pricing
}

type Bonus struct {
	Name        string  // Name of the bonus
	RetailPrice float64 // Retail price of the bonus
	Description string  // Description of the bonus
}
