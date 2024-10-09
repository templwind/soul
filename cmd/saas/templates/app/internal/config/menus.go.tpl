package config

import "github.com/gosimple/slug"

type Menus map[string][]MenuEntry
type MenuEntry struct {
	URL         string
	Title       string
	Subtitle    string
	MobileTitle string
	Lead        string
	InMobile    bool
	Icon        string
	IsAtEnd     bool
	IsDropdown  bool
	HxDisable   bool
	Weight	    int
	Children    []MenuEntry
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

func (c *Config) InitMenus() Menus {
	c.Menus = Menus{
		{{ template "menuSection" . }}
	}

	return c.Menus
}

{{- define "menuSection" -}}
{{- range $menuName, $entries := .menus -}}
	"{{$menuName}}": []MenuEntry{
		{{ range $entries }}
		{{- template "menuEntry" . }}
		{{- end }}
	},
{{- end }}
{{- end -}}

{{- define "menuEntry" -}}
{
	Title: "{{ .Title }}",
	URL:   "{{ .URL }}",
	{{- if .Icon }}
	Icon:  `{{ .Icon }}`,
	{{- end }}
	{{- if .Subtitle }}
	Subtitle: "{{ .Subtitle }}",
	{{- end }}
	{{- if .MobileTitle }}
	MobileTitle: "{{ .MobileTitle }}",
	{{- end }}
	{{- if .Lead }}
	Lead: "{{ .Lead }}",
	{{- end }}
	{{- if .InMobile }}
	InMobile: {{ .InMobile }},
	{{- end }}
	{{- if .IsAtEnd }}
	IsAtEnd: {{ .IsAtEnd }},
	{{- end }}
	{{- if .IsDropdown }}
	IsDropdown: {{ .IsDropdown }},
	{{- end }}
	{{- if .HxDisable }}
	HxDisable: {{ .HxDisable }},
	{{- end }}
	{{- if .Weight }}
	Weight: {{ .Weight }},
	{{- end }}
	{{- if len .Children }}
	Children: []MenuEntry{
		{{- range .Children }}
		{{ template "menuEntry" . }}
		{{- end }}
	},
	{{- end }}
},
{{- end -}}
