package tabpanel

import "fmt"

templ tpl(props *Props) {
	<web-tabpanel>
		<div class="mt-16 grid grid-cols-1 items-center gap-y-2 pt-10 sm:gap-y-6 md:mt-20 lg:grid-cols-12 lg:pt-0">
			<div class="-mx-4 flex overflow-x-auto pb-4 sm:mx-0 sm:overflow-visible sm:pb-0 lg:col-span-5">
				<div class="relative z-10 flex gap-x-4 whitespace-nowrap px-4 sm:mx-auto sm:px-0 lg:mx-0 lg:block lg:gap-x-0 lg:gap-y-1 lg:whitespace-normal" role="tablist" aria-orientation="vertical">
					for i, tab := range props.Tabs {
						<div
							if i == 0 {
								class="group relative rounded-full bg-white px-4 py-1 lg:rounded-l-xl lg:rounded-r-none lg:bg-white/10 lg:p-6 lg:ring-1 lg:ring-inset lg:ring-white/10"
							} else {
								class="group relative rounded-full px-4 py-1 hover:bg-white/10 lg:rounded-l-xl lg:rounded-r-none lg:p-6 lg:hover:bg-white/5"
							}
						>
							<h3>
								<button
									if i == 0 {
										class="font-display ui-not-focus-visible:outline-none text-lg text-blue-600 lg:text-white"
									} else {
										class="font-display ui-not-focus-visible:outline-none text-lg text-blue-100 hover:text-white lg:text-white"
									}
									id={ tab.ID }
									role="tab"
									type="button"
									if i == 0 {
										aria-selected="true"
									} else {
										aria-selected="false"
									}
									tabindex={ fmt.Sprintf("%d", i) }
									aria-controls={ fmt.Sprintf("content-%s", tab.ID) }
								>
									<span class="absolute inset-0 rounded-full lg:rounded-l-xl lg:rounded-r-none"></span>
									{ tab.Label }
								</button>
							</h3>
							<p class="mt-2 hidden text-sm text-white lg:block">
								{ tab.Description }
							</p>
						</div>
					}
				</div>
			</div>
			<div class="lg:col-span-7">
				for i, tab := range props.Tabs {
					<div
						id={ fmt.Sprintf("content-%s", tab.ID) }
						role="tabpanel"
						tabindex={ fmt.Sprintf("%d", i) }
						aria-labelledby={ fmt.Sprintf("content-%s", tab.ID) }
						if i > 0 {
							class="hidden"
						}
					>
						<div class="relative sm:px-6 lg:hidden">
							<div class="absolute -inset-x-4 bottom-[-4.25rem] top-[-6.5rem] bg-white/10 ring-1 ring-inset ring-white/10 sm:inset-x-0 sm:rounded-t-xl"></div>
							<p class="relative mx-auto max-w-2xl text-base text-white sm:text-center">
								{ tab.Description }
							</p>
						</div>
						if tab.Component != nil {
							<div class="h-full w-auto rounded-xl bg-slate-50 shadow-xl shadow-blue-900/20">
								@tab.Component
							</div>
						} else {
							<div class="mt-10 w-[45rem] overflow-hidden rounded-xl bg-slate-50 shadow-xl shadow-blue-900/20 sm:w-auto lg:mt-0 lg:w-[67.8125rem]">
								// <div class="mt-10 flex w-auto items-start rounded-xl bg-slate-50 shadow-xl shadow-blue-900/20 lg:mt-0 lg:h-[812px]">
								if tab.ImageURL != "" {
									<img
										alt={ tab.ImageAlt }
										if i == 0 {
											fetchpriority="high"
										} else {
											fetchpriority="auto"
										}
										decoding="async"
										data-nimg="1"
										class="h-full sm:max-w-[768px] lg:max-w-[1024px]"
										sizes="(min-width: 1024px) 67.8125rem, (min-width: 640px) 100vw, 45rem"
										src={ tab.ImageURL }
									/>
								}
							</div>
						}
					</div>
				}
			</div>
		</div>
	</web-tabpanel>
}
