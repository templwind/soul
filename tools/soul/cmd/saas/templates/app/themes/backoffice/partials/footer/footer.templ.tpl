package footer

import "fmt"

templ tpl(props *Props) {
	<footer class="w-full border-t border-slate-200 bg-slate-300 dark:border-slate-700 dark:bg-slate-900">
		@mobileFooter(props)
		<div class="flex hidden flex-row justify-between">
			<a
				href="/app/encounters"
				class="mb-8 dark:text-white"
				hx-get="/app/encounters"
				hx-push-url="true"
				hx-target="#content"
				hx-on::after-request="window.scrollTo({top: 0, behavior: 'smooth'})"
				if props.MenuEntries != nil {
					x-on:htmx:trigger={ props.HtmxTrigger("/app/encounters", len(props.MenuEntries)) }
				} else {
					x-on:htmx:trigger={ props.HtmxTrigger("/app/encounters", 0) }
				}
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="m-0 h-8 w-auto p-0"
					width="24"
					height="24"
					viewBox="0 0 15 15"
				><path fill="currentColor" d="M1 13V2h4.5a3.5 3.5 0 0 1 3.21 2.103a3.36 3.36 0 0 0-.504.676c-.23.41-.232.837-.174 1.154l.3 1.625A3.495 3.495 0 0 1 5.5 9H3v4zm4.5-6a1.5 1.5 0 1 0 0-3H3v3zm3.516-1.248a.716.716 0 0 1 .062-.484C9.315 4.848 9.978 4 11.5 4c1.521 0 2.185.847 2.421 1.268a.716.716 0 0 1 .064.484L13.019 11H12v2h-1v-2H9.981zM12.75 7L13 5.655C12.83 5.409 12.42 5 11.5 5s-1.33.41-1.5.655L10.25 7z"></path></svg>
			</a>
			if props.MenuEntries != nil {
				for _, item := range props.MenuEntries {
					<a
						href={ templ.URL(item.URL) }
						hx-get={ item.URL }
						hx-push-url="true"
						hx-target="#content"
						hx-on::after-request="window.scrollTo({top: 0, behavior: 'smooth'})"
						if item.Children != nil {
							x-on:htmx:trigger={ props.HtmxTrigger(item.URL, len(item.Children)) }
						} else {
							x-on:htmx:trigger={ props.HtmxTrigger(item.URL, 0) }
						}
						if !item.IsAtEnd && false {
							data-tooltip-target={ item.GetIdentifier("Tool Tip") }
							data-tooltip-placement="right"
						}
						class="z-10 mb-0 rounded-lg p-2 transition-colors duration-200 focus:outline-none"
						:class={ fmt.Sprintf("{'text-blue-500 bg-slate-200 dark:text-white dark:bg-slate-700 md:dark:bg-slate-800' : activeUrl.includes('%s'), 'text-slate-500 dark:text-slate-100 dark:hover:bg-slate-700 hover:bg-slate-200' : !activeUrl.includes('%s')}", item.URL, item.URL) }
					>
						if item.Icon != "" {
							@templ.Raw(item.Icon)
						} else {
							<span class="text-slate-500 dark:text-slate-400">{ item.Title }</span>
						}
					</a>
				}
			}
		</div>
		<div class="hidden w-full justify-between px-4 py-2 align-middle text-xs sm:flex dark:text-slate-300">
			<span>Copyright { props.Year }. All rights reserved.</span>
		</div>
	</footer>
}

templ mobileFooter(props *Props) {
	<div class="fixed bottom-0 left-0 z-50 h-16 w-full border-t border-slate-200 bg-white sm:hidden dark:border-slate-600 dark:bg-slate-700">
		if menu, ok := props.Menus["mobileFooter"]; ok {
			<div class={ "mx-auto grid h-full max-w-lg font-medium", fmt.Sprintf("grid-cols-%d", totalItems(menu)) }>
				for _, item := range menu {
					<button
						type="button"
						class="group inline-flex flex-col items-center justify-center px-5 hover:bg-slate-50 dark:text-white dark:hover:bg-slate-800"
						hx-get={ item.URL }
						hx-target="#content"
						hx-on::after-request="window.scrollTo({top: 0, behavior: 'smooth'})"
						hx-push-url="true"
						x-on:htmx:trigger={ props.HtmxTrigger(item.URL, len(item.Children)) }
					>
						if item.Icon != "" {
							<div class="mb-2 h-5 w-5 text-slate-500 group-hover:text-blue-600 dark:text-slate-400 dark:group-hover:text-blue-500">
								@templ.Raw(item.Icon)
							</div>
						}
						<span
							class="text-sm text-slate-500 group-hover:text-blue-600 dark:text-slate-400 dark:group-hover:text-blue-500"
						>{ item.MobileTitle }</span>
					</button>
				}
			</div>
		}
	</div>
}
