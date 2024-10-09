package menu

import (
	"fmt"
	
	"{{ .serviceName }}/internal/config"
)

templ appRail(props *Props) {
	<aside
		class="order-first m-0 hidden w-16 overflow-y-auto p-0 sm:flex"
		:class="{ 'md:w-64' : drawerIsOpen, 'w-16' : !drawerIsOpen }"
	>
		<div class="z-10 m-0 flex h-full min-w-16 flex-col items-center bg-slate-300 pb-4 pt-3 dark:bg-slate-900">
			<a
				href="/app/encounters"
				class="mb-8 text-black dark:text-slate-500"
				hx-get="/app/encounters"
				hx-target="#content"
				x-on:htmx:trigger={ props.HtmxTrigger("/app/encounters", len(props.Menus[props.MenuKey])) }
			>
				if props.Config.Site.LogoIconSvg != "" {
					@templ.Raw(props.Config.Site.LogoIconSvg)
				}
			</a>
			for _, item := range props.Menus[props.MenuKey] {
				if !item.InMobile {
					if item.IsAtEnd {
						<div class="flex-grow"></div>
					}
					if !item.IsDropdown {
						<div class="relative isolate flex w-full justify-center">
							<div
								class="absolute -top-2 right-0 h-2 w-2"
								:class={ fmt.Sprintf("{'bg-slate-200 dark:bg-slate-700 md:dark:bg-slate-800' : activeUrl.includes('%s')}", item.URL) }
							></div>
							<div
								class="absolute -top-2 right-0 h-2 w-2 rounded-br-lg"
								:class={ fmt.Sprintf("{'bg-slate-300 dark:bg-slate-900' : activeUrl.includes('%s')}", item.URL) }
							></div>
							<div
								class="absolute -bottom-2 right-0 h-2 w-2"
								:class={ fmt.Sprintf("{'bg-slate-200 dark:bg-slate-700 md:dark:bg-slate-800' : activeUrl.includes('%s')}", item.URL) }
							></div>
							<div
								class="absolute -bottom-2 right-0 h-2 w-2 rounded-tr-lg"
								:class={ fmt.Sprintf("{'bg-slate-300 dark:bg-slate-900' : activeUrl.includes('%s')}", item.URL) }
							></div>
							<span
								class="absolute right-0 h-full w-1/2 flex-1"
								:class={ fmt.Sprintf("{'bg-slate-200 dark:bg-slate-700 md:dark:bg-slate-800' : activeUrl.includes('%s')}", item.URL) }
							></span>
							<a
								hx-get={ item.URL }
								hx-push-url="true"
								hx-target="#content"
								if item.Children != nil {
									x-on:htmx:trigger={ props.HtmxTrigger(item.URL, len(item.Children)) }
								} else {
									x-on:htmx:trigger={ props.HtmxTrigger(item.URL, 0) }
								}
								if !item.IsAtEnd && false {
									data-tooltip-target={ item.GetIdentifier(item.Title, " Tool Tip") }
									data-tooltip-placement="right"
								}
								class="z-10 mb-0 cursor-pointer rounded-lg p-2 transition-colors duration-200 focus:outline-none"
								:class={ fmt.Sprintf("{'text-blue-500 bg-slate-200 dark:text-white dark:bg-slate-700 md:dark:bg-slate-800' : activeUrl.includes('%s'), 'text-slate-500 dark:text-slate-100 dark:hover:bg-slate-700 hover:bg-slate-200' : !activeUrl.includes('%s')}", item.URL, item.URL) }
							>
								@templ.Raw(item.Icon)
							</a>
						</div>
					} else {
						<div class="relative">
							<button
								type="button"
								id={ item.MakeTarget(item.Title, " Button") }
								data-dropdown-toggle={ item.MakeTarget(item.Title) }
								data-dropdown-placement="right"
								class="rounded-lg p-1.5 text-slate-500 transition-colors duration-200 hover:bg-slate-100 focus:outline-none dark:text-slate-400 dark:hover:bg-slate-800"
							>
								@templ.Raw(item.Icon)
							</button>
							<div
								id={ item.MakeTarget(item.Title) }
								class="z-10 hidden w-44 divide-y divide-slate-100 rounded-lg bg-white shadow dark:bg-slate-700"
							>
								<ul
									class="py-2 text-sm text-slate-700 dark:text-slate-200"
									aria-labelledby={ item.Title + " Button" }
								>
									for _, subItem := range item.Children {
										<li>
											<a
												href={ templ.URL(subItem.URL) }
												hx-get={ subItem.URL }
												hx-push-url="true"
												hx-target="#content"
												x-on:htmx:trigger={ fmt.Sprintf("activeUrl = '%s'", subItem.URL) }
												class="block cursor-pointer px-4 py-2 hover:bg-slate-100 dark:hover:bg-slate-600 dark:hover:text-white"
											>{ subItem.Title }</a>
										</li>
									}
								</ul>
							</div>
						</div>
					}
				}
			}
		</div>
		<div class="hidden md:block">
			@secondaryNav(props)
		</div>
	</aside>
}

// :class={ fmt.Sprintf("{'translate-x-0' : activeUrl.includes('%s'), '-translate-x-full' : !activeUrl.includes('%s')}", item.URL, item.URL) }
// transition-transform duration-300
templ secondaryNav(props *Props) {
	<div
		class="relative z-0 h-full w-48 overflow-y-auto whitespace-nowrap bg-slate-200 px-0 dark:bg-slate-800"
	>
		for _, item := range props.Menus[props.MenuKey] {
			if len(item.Children) > 0 && !item.IsDropdown {
				<div
					class="absolute h-full w-full whitespace-nowrap pb-4 pt-3"
					:class={ fmt.Sprintf("{'block' : activeUrl.includes('%s'), 'hidden' : !activeUrl.includes('%s')}", item.URL, item.URL) }
				>
					<div class="flex h-full flex-col">
						<div class="mb-8 px-4">
							<h2 class="mt-1 align-text-bottom text-lg font-medium text-slate-800 dark:text-white">{ item.Title }</h2>
						</div>
						<div
							if item.URL == "/app/encounters" {
								hx-post="/app/encounters/search"
								hx-trigger="load, reload-encounter-list from:body"
								hx-target="#patient-list"
								placeholder="Loading..."
							}
							if item.HxDisable {
								hx-disable="true"
							}
							id={ item.MakeTarget(item.URL + " subnav") }
							class="flex h-full flex-col"
						>
							@SecondaryNavMenu(item.Children)
							if item.URL == "/app/encounters" {
								if props.SearchForm != nil {
									@props.SearchForm
								}
								<div id="patient-list"></div>
							}
						</div>
					</div>
				</div>
			}
		}
	</div>
}

templ SecondaryNavMenu(items []config.MenuEntry) {
	for _, subItem := range items {
		if subItem.IsAtEnd {
			<div class="flex-grow"></div>
		}
		<div class="relative isolate flex justify-center hover:z-10">
			<div
				class="absolute -top-2 right-0 h-2 w-2"
				:class={ fmt.Sprintf("{'bg-slate-100 dark:bg-slate-700' : activeUrl === '%s'}", subItem.URL) }
			></div>
			<div
				class="absolute -top-2 right-0 h-2 w-2"
				:class={ fmt.Sprintf("{'bg-slate-200 dark:bg-slate-800 rounded-br-lg' : activeUrl === '%s'}", subItem.URL) }
			></div>
			<div
				class="absolute -bottom-2 right-0 h-2 w-2"
				:class={ fmt.Sprintf("{'bg-slate-100 dark:bg-slate-700' : activeUrl === '%s'}", subItem.URL) }
			></div>
			<div
				class="absolute -bottom-2 right-0 h-2 w-2"
				:class={ fmt.Sprintf("{'bg-slate-200 dark:bg-slate-800 rounded-tr-lg' : activeUrl === '%s'}", subItem.URL) }
			></div>
			<a
				if !subItem.HxDisable {
					hx-get={ subItem.URL }
					hx-target="#content"
					hx-push-url="true"
					x-on:htmx:trigger={ fmt.Sprintf("activeUrl = '%s'", subItem.URL) }
				} else {
					href={ templ.SafeURL(subItem.URL) }
					x-on:htmx:trigger={ fmt.Sprintf("activeUrl = '%s'", subItem.URL) }
				}
				if subItem.HxDisable {
					hx-disable="true"
				}
				class="flex w-full cursor-pointer items-center gap-x-2 whitespace-nowrap rounded-l-lg px-4 py-2 transition-colors duration-0 focus:outline-none"
				:class={ fmt.Sprintf("{'text-blue-500 bg-slate-100 dark:text-white dark:bg-slate-700' : activeUrl === '%s', 'text-gray-500 dark:text-gray-100 dark:hover:bg-slate-700 hover:bg-slate-100' : activeUrl !== '%s'}", subItem.URL, subItem.URL) }
			>
				if subItem.Icon != "" {
					@templ.Raw(subItem.Icon)
				}
				<span class="truncate text-left text-sm font-medium capitalize text-gray-700 rtl:text-right dark:text-white">
					{ subItem.Title }
					if subItem.Subtitle != "" {
						<p class="text-xs text-gray-500 dark:text-gray-400">{ subItem.Subtitle }</p>
					}
				</span>
			</a>
		</div>
	}
}
