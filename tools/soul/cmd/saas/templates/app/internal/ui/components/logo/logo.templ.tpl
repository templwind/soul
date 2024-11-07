package logo

templ tpl(props *Props) {
	if len(props.BrandName) > 0 {
		<div class="text-center">
			{ props.BrandName }
		</div>
	}
	if len(props.Words) > 0 {
		<div class="logo flex flex-wrap justify-center subpixel-antialiased">
			for i, word := range props.Words {
				<span
					class={ props.Size.String(), templ.KV("-ml-1", i > 0), props.Colors[i] }
				>
					{ word }
				</span>
			}
		</div>
	}
}
