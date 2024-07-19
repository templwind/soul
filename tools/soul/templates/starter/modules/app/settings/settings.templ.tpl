package settings

import (
	"fmt"

	"{{ .ModuleName }}/internal/ui/layouts/applayout"
	"{{ .ModuleName }}/internal/ui/components/card"
	"{{ .ModuleName }}/internal/ui/components/appheader"

	"github.com/labstack/echo/v4"
)

templ tpl(props *Props) {
	@applayout.New(
		applayout.WithTitle("Encounter"),
		applayout.WithConfig(props.Config),
		applayout.WithEcho(props.Echo),
	) {
		@appheader.New(
			appheader.WithTitle("Settings"),
		)
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
			for i, item := range cfg.App.RailMenu.SubMenuItems("/app/settings") {
				if !item.IsAtEnd && i >= 1 {
					@card.New(partials.CardConfig{
						Link: &partials.Link{
							HXGet:     item.Link,
							HXSwap:    "innerHTML",
							HXTarget:  "#content",
							HXPushURL: true,
							XOn:       fmt.Sprintf("activeUrl = '%s'", item.Link),
						},
						Title: item.Title,
						Lead:  item.Lead,
						// Components: []templ.Component{Form(e, cfg, model)},
					})
				}
			}
		</div>
	}
}
