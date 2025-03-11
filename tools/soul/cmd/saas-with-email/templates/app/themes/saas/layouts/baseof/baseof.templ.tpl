package baseof

import "{{ .serviceName }}/internal/ui/components/logo"

templ tpl(props *Props) {
	<!DOCTYPE html>
	<html
		data-theme={ props.Theme }
		lang={ props.LangCode }
		dir={ props.LTRDir }
		class="h-full"
	>
		<head>
			if props.Head != nil {
				@props.Head
			}
		</head>
		<body
			class="flex min-w-full min-h-full antialiased"
			hx-boost="true"
		>
			<div class="min-w-full min-h-full drawer md:drawer-open">
				<input id="app-drawer" type="checkbox" class="drawer-toggle"/>
				<div class="flex flex-col min-w-full min-h-full drawer-content">
					<div class="flex-none border-b">
						if props.Header != nil {
							@props.Header
						}
					</div>
					<!-- Page content here -->
					// <label for="app-drawer" class="btn btn-primary drawer-button md:hidden">
					// 	Open drawer
					// </label>
					<div class="flex flex-col flex-1 overflow-x-hidden" style="scrollbar-gutter: auto;">
						// <header
						// 	id="page-header"
						// 	class="flex items-center justify-between flex-none px-4 py-2 bg-white border-b"
						// 	hx-swap-oob="true"
						// ></header>
						<main
							id="page-content"
							class="container flex-1 p-0 mx-auto max-w-screen-2xl"
						>
							if props.Content != nil {
								@props.Content
							}
						</main>
						// <footer class="flex-none"></footer>
						if props.Footer != nil {
							<div class="flex flex-row items-center flex-none py-2 mt-8 bg-base-200">
								@props.Footer
							</div>
						}
					</div>
				</div>
				if props.ShowSidebar {
					<div class="overflow-hidden drawer-side">
						<label for="app-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
						<aside
							class="flex flex-col justify-start min-h-full overflow-x-hidden overflow-y-auto border-r bg-base-200 text-base-content"
						>
							<div class="p-3 px-4">
								<a href={ templ.SafeURL(props.HomeURL) } class="flex items-center text-xl">
									if props.Config.Site.LogoSvg != "" {
										@logo.New(
											logo.WithSize(logo.SizeSmall),
											logo.WithFancyBrandName(props.Config.Site.Title),
										)
										<span class="sr-only">{ props.Config.Site.Title }</span>
									} else {
										if props.Config.Site.Title != "" {
											<h1 class="ml-2 text-2xl font-semibold flex-2">{ props.Config.Site.Title }</h1>
										}
									}
								</a>
							</div>
							<div class="flex-grow">
								if props.SidebarMenu != nil {
									@props.SidebarMenu
								}
							</div>
							<div class="flex-none">
								if props.SidebarFooterMenu != nil {
									@props.SidebarFooterMenu
								}
								if props.SidebarSocialMenu != nil {
									@props.SidebarSocialMenu
								}
							</div>
						</aside>
					</div>
				}
			</div>
			// <div class="z-10 flex-none border-b">
			// 	if props.Header != nil {
			// 		@props.Header
			// 	}
			// </div>
			// <div class="flex flex-auto w-full h-full overflow-hidden">
			// 	if props.SidebarMenu != nil {
			// 		<aside
			// 			id="sidebar-left"
			// 			class="grid flex-none grid-cols-1 overflow-x-hidden overflow-y-auto border-r bg-base-100"
			// 		>
			// 			@props.SidebarMenu
			// 		</aside>
			// 	}
			// 	<div id="page" class="flex flex-col flex-1 overflow-x-hidden" style="scrollbar-gutter: auto;">
			// 		// <header
			// 		// 	id="page-header"
			// 		// 	class="flex items-center justify-between flex-none px-4 py-2 bg-white border-b"
			// 		// 	hx-swap-oob="true"
			// 		// ></header>
			// 		<main
			// 			id="page-content"
			// 			class="container p-4 mx-auto max-w-screen-2xl md:p-6 2xl:p-10"
			// 		>
			// 			if props.Content != nil {
			// 				@props.Content
			// 			}
			// 		</main>
			// 		<footer class="flex-none"></footer>
			// 	</div>
			// 	// <aside class="grid flex-none grid-cols-1 overflow-x-hidden overflow-y-auto"></aside>
			// </div>
			// if props.Footer != nil {
			// 	<div class="flex flex-row items-center flex-none py-2 bg-base-300">
			// 		@props.Footer
			// 	</div>
			// }
		</body>
	</html>
}
