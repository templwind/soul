package terms

templ tpl(props *Props) {
	if len(props.Terms) > 0 {
		<div class="rounded-lg bg-gray-100 p-4">
			<div class="mb-2 text-xl font-semibold">{ props.Label }:</div>
			<ul class="flex flex-wrap gap-2">
				for _, term := range props.Terms {
					<li>
						<a href={ templ.SafeURL(term.RelPermalink) } class="text-blue-600 hover:underline">
							{ term.LinkTitle }
						</a>
					</li>
				}
			</ul>
		</div>
	}
}
