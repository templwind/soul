package section

templ tpl(props *Props) {
	<section
		class={ "section", props.Class }
		if props.ID != "" {
			id={ props.ID }
		}
	>
		<div class="container mx-auto">
			{ children... }
		</div>
	</section>
}
