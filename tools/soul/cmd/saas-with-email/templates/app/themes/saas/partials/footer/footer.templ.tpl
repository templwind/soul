package footer

templ tpl(props *Props) {
	<footer class="flex-none w-full">
		<div class="mx-auto">
			// <nav class="flex justify-center space-x-4">
			// 	if menu, ok := props.Menus["prelaunch-footer"]; ok {
			// 		for _, item := range menu {
			// 			<a href={ templ.SafeURL(item.URL) } class="text-sm link link-hover text-white/70">{ item.Title }</a>
			// 		}
			// 	}
			// </nav>
			<p class="text-xs text-center">&copy; { props.Year } { props.Config.Site.CompanyName } All rights reserved.</p>
		</div>
	</footer>
}
