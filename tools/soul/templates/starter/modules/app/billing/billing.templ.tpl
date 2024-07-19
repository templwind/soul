package billing

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/ui/layouts/applayout"

	"github.com/labstack/echo/v4"
	"{{ .ModuleName }}/internal/templwind/components/appheader"
)

templ tpl(props *Props) {
	@applayout.New(
		applayout.WithTitle("Encounter"),
		applayout.WithConfig(props.Config),
		applayout.WithEcho(props.Echo),
	) {
		@appheader.New(
			appheader.WithTitle("Billing"),
		)
	}
}
