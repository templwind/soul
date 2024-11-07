package page

import (
	"{{ .serviceName }}/internal/ui/components/link"
	"{{ .serviceName }}/internal/ui/components/tabs"
)

templ tpl(props *Props) {
	<div
		class={ templ.KV("sticky top-0 z-50 ", props.IsSticky), "flex items-center justify-between px-4 py-2" }
	>
		<div
			class="flex flex-col items-start w-full text-lg sm:text-2xl md:text-2xl"
		>
			if props.BackLink != nil {
				<div class="flex items-center h-4">
					@link.NewWithProps(props.BackLink)
				</div>
			} else {
				<div class="mt-4"></div>
			}
			if props.TabProps != nil {
				@tabs.NewWithProps(props.TabProps)
			}
			if props.LinkProps != nil {
				@link.NewWithProps(props.LinkProps) {
					@nav(props)
				}
			} else {
				@nav(props)
			}
		</div>
	</div>
	<div class={ "container px-4 pt-2 pb-4", props.MaxContainerWidth }>
		{ children... }
	</div>
}

templ nav(props *Props) {
	// <span class="sm:hidden">
	// 	if !props.HideOnMobile {
	// 		// <svg xmlns="http://www.w3.org/2000/svg" class="w-auto h-6 p-0 m-0" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M20 11v2H8l5.5 5.5l-1.42 1.42L4.16 12l7.92-7.92L13.5 5.5L8 11z"></path></svg>
	// 	}
	// </span>
	<div class="flex items-center justify-between w-full gap-2">
		<div class="flex flex-col">
			<span class="font-semibold">{ props.Title }</span>
			if props.Subtitle != "" {
				<span class="text-xs">{ props.Subtitle }</span>
			}
		</div>
		if props.Buttons != nil {
			<div class="space-x-2">
				for _, button := range props.Buttons {
					@button
				}
			</div>
		}
	</div>
}
