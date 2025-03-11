package eyebrow

templ tpl(props *Props) {
	<div class="font-display mx-auto max-w-4xl tracking-tight antialiased">
		<span class={ "px-4 py-1", props.InnerClass }>
			if len(props.CallOut) > 0 {
				<span class="hidden font-semibold sm:inline">{ props.CallOut }</span>
			}
			{ props.Text }
		</span>
	</div>
}
