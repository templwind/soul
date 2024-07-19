package dashboard

import (
	"{{ .ModuleName }}/internal/ui/components/appheader"
	"{{ .ModuleName }}/internal/ui/layouts/applayout"

	"github.com/labstack/echo/v4"
)

templ tpl(props *Props) {
	@applayout.New(
		applayout.WithTitle("Dashboard"),
		applayout.WithConfig(props.Config),
		applayout.WithEcho(props.Echo),
	) {
		@appheader.New(
			appheader.WithTitle("Billing"),
			appheader.WithHideOnMobile(true),
		)
		<div class="prose">
			<h1>Home</h1>
			<p>Welcome to the dashboard</p>
		</div>
	}
}
