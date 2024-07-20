package config

import (
	{{.imports}}
)

type Config struct {
	webserver.WebServerConf
	db.DBConfig
	{{.auth}}
	{{.jwtTrans}}
	Site struct {
		Title string
		LogoSvg     string
		LogoIconSvg string
	}
	Assets Assets
	Menus  Menus
	GPT              GPT
	Pricing          Pricing
	AllowedCountries map[string]bool `yaml:"AllowedCountries"`
	countryCodeList  map[string]string
}

type Menus map[string][]MenuEntry
type MenuEntry struct {
	URL         string
	Title       string
	Subtitle    string      `yaml:"Subtitle,omitempty"`
	MobileTitle string      `yaml:"MobileTitle,omitempty"`
	Lead        string      `yaml:"Lead,omitempty"`
	InMobile    bool        `yaml:"InMobile,omitempty"`
	Icon        string      `yaml:"Icon,omitempty"`
	IsAtEnd     bool        `yaml:"IsAtEnd,omitempty"`
	IsDropdown  bool        `yaml:"IsDropdown,omitempty"`
	HxDisable   bool        `yaml:"HxDisable,omitempty"`
	Children    []MenuEntry `yaml:"Children,omitempty"`
}

func (m MenuEntry) GetIdentifier(txt ...string) string {
	appendText := ""
	if len(txt) > 0 {
		for _, t := range txt {
			appendText += " " + t
		}
	}
	return slug.Make(m.URL + appendText)
}

func (m MenuEntry) MakeTarget(txt ...string) string {
	targetText := ""
	if len(txt) > 0 {
		for _, t := range txt {
			targetText += " " + t
		}
	}
	return slug.Make(targetText)
}

func (m MenuEntry) GetChildren() []MenuEntry {
	return m.Children
}

type Assets struct {
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

type GPT struct {
	Endpoint      string
	APIKey        string
	OrgID         string
	Model         string
	DallEModel    string `yaml:"DallEModel,omitempty"`
	DallEEndpoint string `yaml:"DallEEndpoint,omitempty"`
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
	Plans          []Plan
	HighlightedIdx int
}

// Plan defines the structure for each pricing plan
type Plan struct {
	Name        string
	Price       string
	Description string
	Features    []string
	ButtonText  string
	URL         string
}
