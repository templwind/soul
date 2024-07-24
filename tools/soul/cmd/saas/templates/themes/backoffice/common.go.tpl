package backoffice

import "{{ .serviceName }}/internal/config"

type Props struct {
	Config      config.Config
	Menus       map[string][]config.MenuEntry
	HtmxTrigger func(path string, count int) string
	XData       string
	XInit       string
	HxSSE       *struct {
		URL string
	}
}
