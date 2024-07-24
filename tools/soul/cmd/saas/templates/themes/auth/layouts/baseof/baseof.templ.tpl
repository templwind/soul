package baseof

templ tpl(props *Props) {
	<!DOCTYPE html>
	<html lang={ props.LangCode } dir={ props.LTRDir } class="h-full antialiased bg-white scroll-smooth">
		<head>
			if props.Head != nil {
				@props.Head
			}
		</head>
		<body
			class="flex flex-col h-full"
			hx-boost="true"
		>
			<div class="relative flex justify-center min-h-full shrink-0 md:px-12 lg:px-0">
				@props.Content
			</div>
		</body>
	</html>
}
