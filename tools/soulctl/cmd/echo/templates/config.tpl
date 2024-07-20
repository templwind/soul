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
	}
	Assets Assets
	Menus  Menus
}

type Menus map[string][]MenuEntry
type MenuEntry struct {
	URL         string
	Title       string
	MobileTitle string      `yaml:"MobileTitle,omitempty"`
	InMobile    bool        `yaml:"InMobile,omitempty"`
	Identifier  string      `yaml:"Identifier,omitempty"`
	Icon        string      `yaml:"Icon,omitempty"`
	Children    []MenuEntry `yaml:"Children,omitempty"`
}

type Assets struct {
	CSS []string
	JS  []string
}