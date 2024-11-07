package selectbox

templ tpl(props *Props) {
	if props.Label != "" {
		<label
			if props.ID != "" {
				for={ props.ID }
			}
			if props.LabelClass != "" {
				class={ props.LabelClass }
			}
		><span class="label-text">{ props.Label }</span></label>
	}
	<select
		if props.ID != "" {
			id={ props.ID }
		}
		if props.Required {
			required
		}
		if props.Class != "" {
			class={ props.Class }
		}
		name={ props.Name }
	>
		if props.InstructionOption != "" {
			<option value="">{ props.InstructionOption }</option>
		}
		for _, option := range props.Options {
			<option
				value={ option.Value }
				if option.Value == props.Selected {
					selected
				}
			>{ option.Text }</option>
		}
	</select>
}
