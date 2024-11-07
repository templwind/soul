package menu

import "{{ .serviceName }}/internal/config"

templ tpl(props *Props) {
	<ul class="flex w-56 min-h-full px-0 py-4 menu">
		@walkMenu(props.MenuEntries)
	</ul>
}

templ walkMenu(entries []config.MenuEntry) {
	for _, entry := range entries {
		<li>
			<a
				href={ templ.SafeURL(entry.URL) }
				class="rounded-none"
			>
				if entry.Icon != "" {
					@templ.Raw(entry.Icon)
				}
				{ entry.Title }
			</a>
			if len(entry.Children) > 0 {
				<ul>
					@walkMenu(entry.Children)
				</ul>
			}
		</li>
	}
}
