package header

templ tpl(props *Props) {
	<web-header>
		<header class="fixed top-0 z-50 w-full h-16 overflow-hidden bg-white border-b border-slate-200">
			<nav class="flex items-center justify-between p-4 lg:px-8" aria-label="Global">
				<div class="flex lg:flex-1">
					<a href="/" class="-m-1.5 p-1.5">
						<span class="sr-only">{ props.BrandName }</span>
						if props.Config.Site.LogoIconSvg != "" {
							@templ.Raw(props.Config.Site.LogoIconSvg)
						}
					</a>
				</div>
				<div class="flex lg:hidden">
					<button type="button" class="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700" id="mobile-menu-button">
						<span class="sr-only">Open main menu</span>
						<svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
							<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"></path>
						</svg>
					</button>
				</div>
				<div class="hidden lg:flex lg:gap-x-12">
					if menu, ok := props.Menus["main"]; ok {
						for _, item := range menu {
							<a href={ templ.SafeURL(item.URL) } class="text-sm font-semibold leading-6 text-gray-900 nav-link">{ item.Title }</a>
						}
					}
				</div>
				if len(props.LoginURL) > 0 {
					<div class="hidden lg:flex lg:flex-1 lg:justify-end">
						<a
							href={ templ.SafeURL(props.LoginURL) }
							hx-disable="true"
							class="text-sm font-semibold leading-6 text-gray-900"
						>{ props.LoginTitle } <span aria-hidden="true">&rarr;</span></a>
					</div>
				}
			</nav>
			<!-- Mobile menu, show/hide based on menu open state. -->
			<div class="hidden lg:hidden" id="mobile-menu" role="dialog" aria-modal="true">
				<!-- Background backdrop, show/hide based on slide-over state. -->
				<div class="fixed inset-0 z-50"></div>
				<div class="fixed inset-y-0 right-0 z-50 w-full px-6 py-6 overflow-y-auto bg-white sm:max-w-sm sm:ring-1 sm:ring-gray-900/10">
					<div class="flex items-center justify-between">
						<a href="/" class="-m-1.5 p-1.5">
							<span class="sr-only">{ props.BrandName }</span>
							<img class="w-auto h-8" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600" alt=""/>
						</a>
						<button type="button" class="-m-2.5 rounded-md p-2.5 text-gray-700" id="close-mobile-menu-button">
							<span class="sr-only">Close menu</span>
							<svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
								<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
							</svg>
						</button>
					</div>
					<div class="flow-root mt-6">
						<div class="-my-6 divide-y divide-gray-500/10">
							<div class="py-6 space-y-2">
								if menu, ok := props.Menus["main"]; ok {
									for _, item := range menu {
										<a href={ templ.SafeURL(item.URL) } class="block px-3 py-2 -mx-3 text-base font-semibold leading-7 text-gray-900 rounded-lg nav-link hover:bg-gray-50">{ item.Title }</a>
									}
								}
							</div>
							if len(props.LoginURL) > 0 {
								<div class="py-6">
									<a href={ templ.SafeURL(props.LoginURL) } class="-mx-3 block rounded-lg px-3 py-2.5 text-base font-semibold leading-7 text-gray-900 hover:bg-gray-50">{ props.LoginTitle }</a>
								</div>
							}
						</div>
					</div>
				</div>
			</div>
		</header>
	</web-header>
}
