package checkbox

templ tpl(props *Props) {
	if props.UseFormControl {
		<div class={ "form-control", templ.KV(props.ContainerClass, props.ContainerClass != "") }>
			@checkboxContent(props)
		</div>
	} else {
		@checkboxContent(props)
	}
}

templ checkboxContent(props *Props) {
	<label class={ "label cursor-pointer", templ.KV(props.ContainerClass, props.ContainerClass != "" && !props.UseFormControl) }>
		if props.LabelPosition == "left" {
			<span class={ "label-text", templ.KV(props.LabelClass, props.LabelClass != "") }>
				@templ.Raw(props.Label)
			</span>
		}
		<input
			type="checkbox"
			class={ "checkbox", templ.KV(props.Class, props.Class != "") }
			if props.ID != "" {
				id={ props.ID }
			}
			if props.Name != "" {
				name={ props.Name }
			}
			if props.Checked {
				checked
			}
			if props.Required {
				required
			}
			if props.Value != "" {
				value={ props.Value }
			}
		/>
		if props.LabelPosition == "right" {
			<span class={ "label-text", templ.KV(props.LabelClass, props.LabelClass != "") }>
				@templ.Raw(props.Label)
			</span>
		}
	</label>
}
