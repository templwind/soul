package contact

templ tpl(props *Props) {
	<div class="relative isolate bg-white">
		<div class="mx-auto grid max-w-7xl grid-cols-1 lg:grid-cols-2">
			<div class="relative px-6 pb-20 pt-24 sm:pt-32 lg:static lg:px-8 lg:py-48">
				<div class="mx-auto max-w-xl lg:mx-0 lg:max-w-lg">
					<div class="absolute inset-y-0 left-0 -z-10 w-full overflow-hidden lg:w-1/2"></div>
					<h2 class="mb-6 text-3xl font-bold tracking-tight text-gray-900">Get in touch</h2>
					if len(props.Description) > 0 {
						for _, desc := range props.Description {
							<p class="text-lg leading-8 text-gray-600">{ desc }</p>
						}
					}
					<dl class="mt-10 space-y-4 text-base leading-7 text-gray-600">
						if props.Address != "" || props.City != "" || props.StateProvince != "" || props.Country != "" {
							<div class="flex gap-x-4">
								<dt class="flex-none">
									<span class="sr-only">Address</span>
									<svg class="h-7 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
										<path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"></path>
										<path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"></path>
									</svg>
								</dt>
								<dd>
									if props.Address != "" {
										<div>{ props.Address }</div>
									}
									if props.Address2 != "" {
										<div>{ props.Address2 }</div>
									}
									if props.City != "" || props.StateProvince != "" {
										<div>
											if props.City != "" {
												{ props.City }
												if props.StateProvince != "" {
													, 
												}
											}
											if props.StateProvince != "" {
												{ props.StateProvince }
											}
										</div>
									}
									if props.Country != "" {
										<div>{ props.Country }</div>
									}
								</dd>
							</div>
						}
						if props.Phone != "" {
							<div class="flex gap-x-4">
								<dt class="flex-none">
									<span class="sr-only">Telephone</span>
									<svg class="h-7 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
										<path stroke-linecap="round" stroke-linejoin="round" d="M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 002.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 01-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 00-1.091-.852H4.5A2.25 2.25 0 002.25 4.5v2.25z"></path>
									</svg>
								</dt>
								<dd><a class="hover:text-gray-900" href={ templ.SafeURL("tel:" + props.Phone) }>{ props.Phone }</a></dd>
							</div>
						}
						if props.Email != "" {
							<div class="flex gap-x-4">
								<dt class="flex-none">
									<span class="sr-only">Email</span>
									<svg class="h-7 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
										<path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"></path>
									</svg>
								</dt>
								<dd><a class="hover:text-gray-900" href={ templ.SafeURL("mailto:" + props.Email) }>{ props.Email }</a></dd>
							</div>
						}
					</dl>
				</div>
			</div>
			<form
				hx-post="/contact"
				class="rounded-lg px-6 pb-24 pt-20 shadow-lg sm:pb-32 lg:px-8 lg:py-48"
			>
				<div class="mx-auto max-w-xl lg:mr-0 lg:max-w-lg">
					<div class="grid grid-cols-1 gap-x-8 gap-y-6 sm:grid-cols-2">
						<div>
							<label for="name" class="block text-sm font-semibold leading-6 text-gray-900">Name</label>
							<div class="mt-2.5">
								<input type="text" name="name" id="name" autocomplete="given-name" class="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"/>
							</div>
						</div>
						<div>
							<label for="email" class="block text-sm font-semibold leading-6 text-gray-900">Email</label>
							<div class="mt-2.5">
								<input type="email" name="email" id="email" autocomplete="email" class="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"/>
							</div>
						</div>
						<div class="sm:col-span-2">
							<label for="message" class="block text-sm font-semibold leading-6 text-gray-900">Leave us a message</label>
							<div class="mt-2.5">
								<textarea name="message" id="message" rows="4" class="block w-full rounded-md border-0 px-3.5 py-2 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"></textarea>
							</div>
						</div>
					</div>
					<div class="mt-8 flex justify-end">
						<button type="submit" class="btn btn-primary">Send message</button>
					</div>
				</div>
			</form>
		</div>
	</div>
}
