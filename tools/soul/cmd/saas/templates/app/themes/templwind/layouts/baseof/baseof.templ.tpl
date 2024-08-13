package baseof

templ tpl(props *Props) {
	<!DOCTYPE html>
	<html lang={ props.LangCode } dir={ props.LTRDir } class="h-full bg-white">
		<head>
			if props.Head != nil {
				@props.Head
			}
		</head>
		<body
			class="flex min-h-full flex-col bg-white antialiased"
			hx-boost="true"
		>
			if props.Header != nil {
				@props.Header
			}
			if props.Content != nil {
				<main class="relative isolate h-full flex-1 pt-32">
					@props.Content
				</main>
			}
			if props.Footer != nil {
				@props.Footer
			}
		</body>
	</html>
}
