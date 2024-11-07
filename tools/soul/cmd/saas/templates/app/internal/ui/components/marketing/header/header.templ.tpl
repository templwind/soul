package header

templ tpl(props *Props) {
	<div class="flex flex-col items-center justify-center bg-primary py-24 text-center">
		<h1 class="text-3xl font-bold">{ props.H1 }</h1>
		<h2 class="mt-4 text-xl">{ props.H2 }</h2>
	</div>
}
