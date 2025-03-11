package button

templ buttonView(props *Props) {
	<button
		type={ props.Type }
		class={ props.Class }
		if props.OnClick != "" {
			onclick={ onClickHandler(templ.JSExpression(props.OnClick)) }
		}
		if props.HxGet != "" {
			hx-get={ props.HxGet }
		}
		if props.HxPost != "" {
			hx-post={ props.HxPost }
		}
		if props.HxPut != "" {
			hx-put={ props.HxPut }
		}
		if props.HxDelete != "" {
			hx-delete={ props.HxDelete }
		}
		if props.HxTarget != "" {
			hx-target={ props.HxTarget }
		}
		if props.HXSwap != "" {
			hx-swap={ props.HXSwap }
		}
	>
		{ props.Label }
	</button>
}

script onClickHandler(funcCall templ.JSExpression) {
	funcCall
}
