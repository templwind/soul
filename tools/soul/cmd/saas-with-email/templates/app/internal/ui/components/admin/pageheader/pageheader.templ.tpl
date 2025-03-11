package pageheader

templ tpl(props *Props) {
	<div
		id={ props.ID }
		class={ "flex items-center justify-between flex-none px-4 py-2 bg-white border-b", templ.KV(props.Class, props.Class != "") }
	>
		if props.Href != "" {
			<div class="flex flex-col items-center mr-2">
				<a href={ props.Href } class="px-1 btn btn-sm btn-ghost">
					<svg xmlns="http://www.w3.org/2000/svg" class="w-8 h-8" viewBox="0 0 12 24">
						<path fill="currentColor" fill-rule="evenodd" d="m3.343 12l7.071 7.071L9 20.485l-7.778-7.778a1 1 0 0 1 0-1.414L9 3.515l1.414 1.414z"></path>
					</svg>
				</a>
			</div>
		}
		<h1 class="text-2xl font-bold">{ props.Title }</h1>
		if props.Buttons != nil {
			<div class="flex flex-row gap-2">
				for _, button := range props.Buttons {
					@button
				}
			</div>
		}
	</div>
}
