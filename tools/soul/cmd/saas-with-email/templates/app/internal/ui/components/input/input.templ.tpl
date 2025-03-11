package input

templ tpl(props *Props) {
	<input
		type={ props.Type }
		name={ props.Name }
		placeholder={ props.Placeholder }
		required?={ props.Required }
		class={ props.Class }
	/>
}
