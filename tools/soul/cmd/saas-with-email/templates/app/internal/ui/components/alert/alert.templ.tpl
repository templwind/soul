package alert

templ tpl(props *Props) {
	<tw-alert
		class="w-full"
		if props.Hide {
			hide-duration={ props.HideDuration }
		}
	>
		<div
			if props.ID != "" {
				id={ props.ID }
			}
			role="alert"
			class={ "alert", props.Class, templ.KV("shadow-lg", props.Shadow), templ.KV("alert-info", props.Type.isInfo()), templ.KV("alert-success", props.Type.isSuccess()), templ.KV("alert-warning", props.Type.isWarning()), templ.KV("alert-error", props.Type.isError()) }
		>
			if props.IconSVG != "" || props.IconComponent != nil {
				if props.IconSVG != "" {
					@templ.Raw(props.IconSVG)
				}
				if props.IconComponent != nil {
					@props.IconComponent
				}
			} else {
				<span></span>
			}
			if props.Title != "" {
				<div>
					<h3 class="font-bold">{ props.Title }</h3>
					if props.Message != "" {
						<span class="text-sm">
							@templ.Raw(props.Message)
						</span>
					}
				</div>
			} else {
				if props.Message != "" {
					<div class="text-sm">
						@templ.Raw(props.Message)
					</div>
				}
			}
			if props.Buttons != nil {
				if len(props.Buttons) > 1 {
					<div>
						for _, button := range props.Buttons {
							@button
						}
					</div>
				} else {
					for _, button := range props.Buttons {
						@button
					}
				}
			}
			if props.CloseButton {
				<button class="close">&times;</button>
			}
		</div>
	</tw-alert>
}
