package card

import "{{ .serviceName }}/internal/ui/components/indicator"

templ tpl(props *Props) {
	<div class={ "p-4", props.Class }>
		if props.HeadIndicator != nil {
			<div class="grid-cols-3 gap-4 test">
				<h5 class="col-span-2 mb-2 text-2xl font-bold tracking-tight card-title text-base-content">{ props.Title }</h5>
				<div class="col-span-1 text-right">
					if props.HeadIndicator != nil {
						@indicator.NewWithProps(props.HeadIndicator)
					}
				</div>
			</div>
		} else {
			if props.Title != "" {
				<div class={ "mb-2 flex w-full items-center justify-between gap-2",  props.TitleClass }>
					<h5
						class="flex flex-col text-xl font-semibold tracking-tighter text-base-content"
					>
						{ props.Title }
						if props.TitleSubscript != "" {
							<div class="block text-xs text-base-content/50">{ props.TitleSubscript }</div>
						}
					</h5>
					if props.TitleButtons != nil {
						<div class="space-x-2">
							for _, button := range props.TitleButtons {
								@button
							}
						</div>
					}
				</div>
			}
		}
		if props.SubTitle != "" {
			<h6 class="mb-2 text-xs font-semibold tracking-tight uppercase text-base-content">{ props.SubTitle }</h6>
		}
		if props.Lead != "" {
			<p class="text-sm text-gray-700">{ props.Lead }</p>
		}
		{ children... }
	</div>
	if len(props.Components) > 0 {
		for _, c := range props.Components {
			@c
		}
	}
	if props.Buttons != nil {
		@props.Buttons
	}
}
