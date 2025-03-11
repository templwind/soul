package pagetitle

import "{{ .serviceName }}/internal/ui/components/link"

templ tpl(props *Props) {
	<div
		class={ templ.KV("sticky top-0 z-50 ", props.IsSticky), "flex items-center justify-between px-4 py-2" }
	>
		<div
			class="flex w-full flex-row items-center text-lg capitalize sm:text-2xl md:text-2xl"
		>
			if props.LinkProps != nil {
				@link.NewWithProps(props.LinkProps) {
					@body(props)
				}
			} else {
				@body(props)
			}
		</div>
		if !props.HideOnMobile {
			<span class="z-50 text-xs">
				{ children... }
			</span>
		}
	</div>
}

templ body(props *Props) {
	<span class="sm:hidden">
		if !props.HideOnMobile {
			// <svg xmlns="http://www.w3.org/2000/svg" class="m-0 h-6 w-auto p-0" width="24" height="24" viewBox="0 0 24 24"><path fill="currentColor" d="M20 11v2H8l5.5 5.5l-1.42 1.42L4.16 12l7.92-7.92L13.5 5.5L8 11z"></path></svg>
		}
	</span>
	<div class="flex w-full items-center justify-between gap-2">
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
