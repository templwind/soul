package edit

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/ui/layouts/applayout"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/partials"

	"github.com/labstack/echo/v4"
	// "{{ .ModuleName }}/internal/templwind/components/appheader"
)

templ Edit(e echo.Context, cfg *config.Config, account *models.Account) {
	@applayout.New(
		applayout.WithTitle("Encounter"),
		applayout.WithConfig(cfg),
		applayout.WithEcho(e),
	) {
		// @appheader.New(
		// 	appheader.WithTitle("Account"),
		// )
		@partials.FormContainer() {
			// @partials.Card(partials.CardConfig{
			// 	Lead:       "Update you account information.",
			// 	Components: []templ.Component{Form(e, cfg, account)},
			// })
		}
	}
}
