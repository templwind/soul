package header

templ tpl(props *Props) {
	<web-header>
		<header class="fixed top-0 z-50 w-full bg-white py-10">
			<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
				<nav class="relative z-50 flex justify-between">
					<div class="flex items-center md:gap-x-12">
						<a
							href="/"
							aria-label="Home"
							class="text-blue-600"
						>
							<span class="sr-only">{ props.BrandName }</span>
							if props.Config.Site.LogoSvg != "" {
								@templ.Raw(props.Config.Site.LogoSvg)
							}
						</a>
						<div class="hidden md:flex md:gap-x-6">
							if menu, ok := props.Menus["main"]; ok {
								for _, item := range menu {
									<a href={ templ.SafeURL(item.URL) } class="inline-block rounded-lg px-2 py-1 text-sm text-slate-700 hover:bg-slate-100 hover:text-slate-900">{ item.Title }</a>
								}
							}
						</div>
					</div>
					<div class="flex items-center gap-x-5 md:gap-x-8">
						if menu, ok := props.Menus["signin"]; ok {
							for _, item := range menu {
								<div class="hidden md:block">
									<a
										hx-disable="true"
										href={ templ.SafeURL(item.URL) }
										class="inline-block rounded-lg px-2 py-1 text-sm text-slate-700 hover:bg-slate-100 hover:text-slate-900"
									>{ item.Title }</a>
								</div>
							}
						}
						if menu, ok := props.Menus["register"]; ok {
							for _, item := range menu {
								<a
									class="group inline-flex items-center justify-center rounded-full bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-500 hover:text-slate-100 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 active:bg-blue-800 active:text-blue-100"
									hx-disable="true"
									href={ templ.SafeURL(item.URL) }
								><span>Get started <span class="hidden lg:inline">today</span></span></a>
							}
						}
						<div class="-mr-1 md:hidden">
							<div>
								<button
									class="ui-not-focus-visible:outline-none relative z-10 flex h-8 w-8 items-center justify-center"
									aria-label="Toggle Navigation"
									type="button"
									aria-expanded="false"
									id="mobile-menu-button"
								>
									<svg
										aria-hidden="true"
										class="h-3.5 w-3.5 overflow-visible stroke-slate-700"
										fill="none"
										stroke-width="2"
										stroke-linecap="round"
									>
										<path d="M0 1H14M0 7H14M0 13H14" class="origin-center transition"></path>
										<path d="M2 2L12 12M12 2L2 12" class="origin-center scale-90 opacity-0 transition"></path>
									</svg>
								</button>
							</div>
							<div class="-mr-1 md:hidden">
								<div>
									<button
										class="ui-not-focus-visible:outline-none relative z-10 flex h-8 w-8 items-center justify-center"
										aria-label="Toggle Navigation"
										type="button"
										aria-expanded="true"
										id="mobile-menu-button"
										aria-controls="mobile-menu"
									>
										<svg aria-hidden="true" class="h-3.5 w-3.5 overflow-visible stroke-slate-700" fill="none" stroke-width="2" stroke-linecap="round"><path d="M0 1H14M0 7H14M0 13H14" class="origin-center scale-90 opacity-0 transition"></path><path d="M2 2L12 12M12 2L2 12" class="origin-center transition"></path></svg>
									</button>
									<div
										class="fixed inset-0 bg-slate-300/50 duration-150 data-[closed]:opacity-0 data-[enter]:ease-out data-[leave]:ease-in"
										id="mobile-menu"
										aria-hidden="true"
									></div>
									<div
										class="absolute inset-x-0 top-full mt-4 flex origin-top flex-col rounded-2xl bg-white p-4 text-lg tracking-tight text-slate-900 shadow-xl ring-1 ring-slate-900/5 data-[closed]:scale-95 data-[closed]:opacity-0 data-[enter]:duration-150 data-[leave]:duration-100 data-[enter]:ease-out data-[leave]:ease-in"
										id="headlessui-popover-panel-:Rdv6fja:"
										tabindex="-1"
									>
										if menu, ok := props.Menus["main"]; ok {
											for _, item := range menu {
												<a
													href={ templ.SafeURL(item.URL) }
													class="block w-full p-2"
												>{ item.Title }</a>
											}
										}
										<hr class="m-2 border-slate-300/40"/>
										if menu, ok := props.Menus["signin"]; ok {
											for _, item := range menu {
												<a
													hx-disable="true"
													href={ templ.SafeURL(item.URL) }
													class="block w-full p-2"
												>{ item.Title }</a>
											}
										}
										if menu, ok := props.Menus["register"]; ok {
											for _, item := range menu {
												<a
													class="block w-full p-2"
													hx-disable="true"
													href={ templ.SafeURL(item.URL) }
												>{ item.Title }</a>
											}
										}
									</div>
								</div>
								<div
									style="position:fixed;top:1px;left:1px;width:1px;height:0;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;border-width:0;display:none"
								></div>
							</div>
						</div>
					</div>
				</nav>
			</div>
		</header>
	</web-header>
}

templ tplOld(props *Props) {
	<web-header>
		<header class="fixed top-0 z-50 h-16 w-full overflow-hidden border-b border-slate-200 bg-white">
			<nav class="flex items-center justify-between p-4 lg:px-8" aria-label="Global">
				<div class="flex lg:flex-1">
					<a href="/" class="-m-1.5 p-1.5">
						<span class="sr-only">{ props.BrandName }</span>
						if props.Config.Site.LogoSvg != "" {
							@templ.Raw(props.Config.Site.LogoSvg)
						}
					</a>
				</div>
				<div class="flex lg:hidden">
					<button type="button" class="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700" id="mobile-menu-button">
						<span class="sr-only">Open main menu</span>
						<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
							<path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"></path>
						</svg>
					</button>
				</div>
				<div class="hidden lg:flex lg:gap-x-12">
					if menu, ok := props.Menus["main"]; ok {
						for _, item := range menu {
							<a href={ templ.SafeURL(item.URL) } class="nav-link text-sm font-semibold leading-6 text-gray-900">{ item.Title }</a>
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
				<div class="fixed inset-y-0 right-0 z-50 w-full overflow-y-auto bg-white px-6 py-6 sm:max-w-sm sm:ring-1 sm:ring-gray-900/10">
					<div class="flex items-center justify-between">
						<a href="/" class="-m-1.5 p-1.5">
							<span class="sr-only">{ props.BrandName }</span>
							<img class="h-8 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600" alt=""/>
						</a>
						<button type="button" class="-m-2.5 rounded-md p-2.5 text-gray-700" id="close-mobile-menu-button">
							<span class="sr-only">Close menu</span>
							<svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
								<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
							</svg>
						</button>
					</div>
					<div class="mt-6 flow-root">
						<div class="-my-6 divide-y divide-gray-500/10">
							<div class="space-y-2 py-6">
								if menu, ok := props.Menus["main"]; ok {
									for _, item := range menu {
										<a href={ templ.SafeURL(item.URL) } class="nav-link -mx-3 block rounded-lg px-3 py-2 text-base font-semibold leading-7 text-gray-900 hover:bg-gray-50">{ item.Title }</a>
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
