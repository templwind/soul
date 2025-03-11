package apprail

import (
	"fmt"
	"{{ .serviceName }}/internal/ui/components/link"
)

templ tpl(props *Props) {
	<div
		class={ fmt.Sprintf("app-rail border-r grid grid-rows-[auto_1fr_auto] overflow-y-auto bg-slate-300 dark:bg-slate-90 %s %s %s %s %s", props.Background, props.Border, props.Width, props.Height, props.Gap) }
		data-testid="app-rail"
	>
		if props.Lead != nil {
			<div class="app-bar-lead box-border">
				@props.Lead
			</div>
		}
		<div class="app-bar-default flex flex-col w-full box-border divide-y">
			for _, item := range props.MenuItems {
				@link.NewWithProps(item) {
					<div
						class="w-full flex flex-col items-center justify-center space-y-1 p-2 text-xs text-center dark:text-white"
					>
						if item.Icon != "" {
							@templ.Raw(item.Icon)
						}
						<span>{ item.Title }</span>
					</div>
				}
			}
			{ children... }
		</div>
		if props.Trail != nil {
			<div class="app-bar-trail box-border">
				@props.Trail
			</div>
		}
	</div>
}
