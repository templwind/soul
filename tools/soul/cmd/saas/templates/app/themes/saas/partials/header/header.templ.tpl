package header

templ tpl(props *Props) {
	<header class="w-full text-base">
		if props.CallOut != nil {
			<div class={ "flex items-center justify-center py-2 text-xs sm:text-base", props.CallOutCss }>
				@props.CallOut
			</div>
		}
		<nav class="container w-full px-4 py-2 mx-auto" role="navigation">
			<div class="relative flex items-center justify-between lg:flex-row">
				<div class="w-fit">
					<div class="flex items-center gap-4">
						<div class="flex flex-col items-center justify-start justify-items-start gap-0.5">
							<p class="w-full font-semibold">{ props.AccountName }</p>
							if props.SubscriptionCtx != nil {
								<p class="w-full text-base">{ props.SubscriptionCtx.Product.Name }</p>
							} else {
								<p class="w-full text-base">Free</p>
							}
						</div>
					</div>
				</div>
				<div class="py-3 w-fit">
					<div class="flex items-center gap-4 rounded-md">
						// <div class="flex items-center gap-2 cursor-pointer">
						// 	<a href="https://seamailer.tawk.help/" target="_blank" class="rounded-xl p-1.5 hover:bg-primary/10">
						// 		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="22" height="22" fill="currentColor">
						// 			<g>
						// 				<path d="M232,56V200H160a32,32,0,0,0-32,32V88a32,32,0,0,1,32-32Z" opacity="0.2"></path>
						// 				<path d="M232,48H160a40,40,0,0,0-32,16A40,40,0,0,0,96,48H24a8,8,0,0,0-8,8V200a8,8,0,0,0,8,8H96a24,24,0,0,1,24,24,8,8,0,0,0,16,0,24,24,0,0,1,24-24h72a8,8,0,0,0,8-8V56A8,8,0,0,0,232,48ZM96,192H32V64H96a24,24,0,0,1,24,24V200A39.81,39.81,0,0,0,96,192Zm128,0H160a39.81,39.81,0,0,0-24,8V88a24,24,0,0,1,24-24h64ZM160,88h40a8,8,0,0,1,0,16H160a8,8,0,0,1,0-16Zm48,40a8,8,0,0,1-8,8H160a8,8,0,0,1,0-16h40A8,8,0,0,1,208,128Zm0,32a8,8,0,0,1-8,8H160a8,8,0,0,1,0-16h40A8,8,0,0,1,208,160Z"></path>
						// 			</g>
						// 		</svg>
						// 	</a>
						// 	<a href="https://www.youtube.com/@seamailerapp" target="_blank" class="rounded-xl p-1.5 hover:bg-primary/10">
						// 		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="22" height="22" fill="currentColor">
						// 			<g>
						// 				<path d="M226.59,71.53a16,16,0,0,0-9.63-11C183.48,47.65,128,48,128,48s-55.48-.35-89,12.58a16,16,0,0,0-9.63,11C27.07,80.54,24,98.09,24,128s3.07,47.46,5.41,56.47A16,16,0,0,0,39,195.42C72.52,208.35,128,208,128,208s55.48.35,89-12.58a16,16,0,0,0,9.63-10.95c2.34-9,5.41-26.56,5.41-56.47S228.93,80.54,226.59,71.53ZM112,160V96l48,32Z" opacity="0.2"></path>
						// 				<path d="M164.44,121.34l-48-32A8,8,0,0,0,104,96v64a8,8,0,0,0,12.44,6.66l48-32a8,8,0,0,0,0-13.32ZM120,145.05V111l25.58,17ZM234.33,69.52a24,24,0,0,0-14.49-16.4C185.56,39.88,131,40,128,40s-57.56-.12-91.84,13.12a24,24,0,0,0-14.49,16.4C19.08,79.5,16,97.74,16,128s3.08,48.5,5.67,58.48a24,24,0,0,0,14.49,16.41C69,215.56,120.4,216,127.34,216h1.32c6.94,0,58.37-.44,91.18-13.11a24,24,0,0,0,14.49-16.41c2.59-10,5.67-28.22,5.67-58.48S236.92,79.5,234.33,69.52Zm-15.49,113a8,8,0,0,1-4.77,5.49c-31.65,12.22-85.48,12-86.12,12s-54.37.18-86-12a8,8,0,0,1-4.77-5.49C34.8,173.39,32,156.57,32,128s2.8-45.39,5.16-54.47A8,8,0,0,1,41.93,68C73.58,55.82,127.4,56,128.05,56s54.37-.18,86,12a8,8,0,0,1,4.77,5.49C221.2,82.61,224,99.43,224,128S221.2,173.39,218.84,182.47Z"></path>
						// 			</g>
						// 		</svg>
						// 	</a>
						// 	<div class="h-10 w-[2px]"></div>
						// </div>
						<div class="hidden flex-col items-end gap-0.5 md:flex">
							<p class="font-bold">{ props.FirstName }</p>
							<span class="text-base">{ props.Email }</span>
						</div>
						<div class="flex flex-row items-center gap-1.5 rounded-xl bg-[#F8F9FB] px-3 py-2 hover:bg-[#F0F3FB]">
							<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="#14213d" viewBox="0 0 256 256">
								<path d="M224,128a95.76,95.76,0,0,1-31.8,71.37A72,72,0,0,0,128,160a40,40,0,1,0-40-40,40,40,0,0,0,40,40,72,72,0,0,0-64.2,39.37h0A96,96,0,1,1,224,128Z" opacity="0.2"></path>
								<path d="M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24ZM74.08,197.5a64,64,0,0,1,107.84,0,87.83,87.83,0,0,1-107.84,0ZM96,120a32,32,0,1,1,32,32A32,32,0,0,1,96,120Zm97.76,66.41a79.66,79.66,0,0,0-36.06-28.75,48,48,0,1,0-59.4,0,79.66,79.66,0,0,0-36.06,28.75,88,88,0,1,1,131.52,0Z"></path>
							</svg>
							<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 256 256" class="transition-transform duration-300 ease-in-out">
								<path d="M216.49,104.49l-80,80a12,12,0,0,1-17,0l-80-80a12,12,0,0,1,17-17L128,159l71.51-71.52a12,12,0,0,1,17,17Z"></path>
							</svg>
						</div>
					</div>
				</div>
				<div class="absolute right-0 z-20 mt-2 flex cursor-default flex-col gap-1 rounded-[9px] border bg-[#F8F9FB] p-2">
					if menu, ok := props.Menus["app-main"]; ok {
						for _, item := range menu {
							<a href={ templ.SafeURL(item.URL) } class="btn btn-ghost btn-sm sm:btn-md">{ item.Title }</a>
						}
					}
				</div>
			</div>
		</nav>
	</header>
	<!--header class="w-full">
		if props.CallOut != nil {
			<div class="flex items-center justify-center py-2 text-xs bg-base-300 sm:text-base">
				@props.CallOut
			</div>
		}
		if len(props.BrandName) > 0 || props.Config.Site.LogoSvg != "" {
			<nav class="px-2 mx-auto navbar lg:container sm:px-2">
				<div class="flex-none md:hidden">
					<label for="app-drawer" aria-label="open sidebar" class="btn btn-square btn-ghost">
						<svg
							xmlns="http://www.w3.org/2000/svg"
							fill="none"
							viewBox="0 0 24 24"
							class="inline-block w-6 h-6 stroke-current"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M4 6h16M4 12h16M4 18h16"
							></path>
						</svg>
					</label>
				</div>
				<div class="flex-1 hidden ml-4 sm:flex md:ml-8">
					if menu, ok := props.Menus["app-main"]; ok {
						for _, item := range menu {
							<a href={ templ.SafeURL(item.URL) } class="btn btn-ghost btn-sm sm:btn-md">{ item.Title }</a>
						}
					}
				</div>
			</nav>
		}
	</header-->
}
