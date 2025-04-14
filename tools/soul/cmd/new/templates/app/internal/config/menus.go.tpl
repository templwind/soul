package config

import (
	"reflect"
	"strconv"
	"strings"

	"github.com/gosimple/slug"
)

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
	Attributes  map[string]string
	IsButton    bool
	Children    []MenuEntry
}

// BuildRoute takes a map of parameters and returns the processed URL with any dynamic segments replaced.
// If the URL has no dynamic segments (no ":" character), it returns the original URL unchanged.
func (m MenuEntry) BuildRoute(data any) string {
    // If no dynamic segments or no data provided, return original
    if !strings.Contains(m.URL, ":") || data == nil {
        return m.URL
    }

    result := m.URL
    
    // Use reflection to examine the struct fields
    v := reflect.ValueOf(data)
    if v.Kind() == reflect.Ptr {
        v = v.Elem()
    }
    
    if v.Kind() != reflect.Struct {
        return m.URL
    }
    
    t := v.Type()
    for i := 0; i < t.NumField(); i++ {
        field := t.Field(i)
        // Get the path tag value
        pathTag := field.Tag.Get("path")
        if pathTag != "" {
            // Get the field value as string
            fieldValue := v.Field(i)
            var stringValue string
            
            // Convert the field value to string based on its kind
            switch fieldValue.Kind() {
            case reflect.String:
                stringValue = fieldValue.String()
            case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
                stringValue = strconv.FormatInt(fieldValue.Int(), 10)
            case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
                stringValue = strconv.FormatUint(fieldValue.Uint(), 10)
            case reflect.Float32, reflect.Float64:
                stringValue = strconv.FormatFloat(fieldValue.Float(), 'f', -1, 64)
            case reflect.Bool:
                stringValue = strconv.FormatBool(fieldValue.Bool())
            default:
                continue
            }
            
            // Replace the parameter in the URL
            result = strings.Replace(result, ":"+pathTag, stringValue, -1)
        }
    }
    
    return result
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
	{{- if .Attributes }}
	Attributes: {{ ConvertAttributesToMap .Attributes }},
	{{- end }}
	{{- if .IsButton }}
	IsButton: {{ .IsButton }},
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
