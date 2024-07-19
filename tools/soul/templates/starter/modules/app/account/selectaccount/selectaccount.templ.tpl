package selectaccount

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/layouts"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"
	"{{ .ModuleName }}/internal/ui/components/appheader"
	"{{ .ModuleName }}/internal/ui/components/card"
	"{{ .ModuleName }}/internal/ui/components/link"

	"github.com/labstack/echo/v4"
)

templ tpl(e echo.Context, cfg *config.Config, accounts []*models.Account) {
	@layouts.BaseLayout(e, cfg) {
		@appheader.New(
			appheader.WithTitle("Billing"),
			appheader.WithHideOnMobile(true),
		)
		<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
			for _, account := range accounts {
				@link.New(
					link.WithHXPost("/app/choose-account/"+account.ID),
					link.WithHXTarget("#content"),
				) {
					@card.New(
						card.WithTitle(types.NewStringFromNull(account.CompanyName)),
						card.WithLead("Choose account"),
					)
				}
			}
		</div>
	}
}
