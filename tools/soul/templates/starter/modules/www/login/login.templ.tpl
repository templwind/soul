package login

import (
	"{{ .ModuleName }}/internal/ui/layouts/sitelayout"
)

templ tpl(props *Props) {
	@sitelayout.New(
		sitelayout.WithEcho(props.Echo),
		sitelayout.WithConfig(props.Config),
	) {
		<div class="flex flex-col items-center justify-center h-full">
			<div class="w-full max-w-sm p-4 bg-white border rounded-lg shadow border-slate-200 sm:p-6 md:p-8 dark:bg-slate-800 dark:border-slate-700">
				<form class="max-w-md mx-auto space-y-4" hx-post="/login" hx-target="#form-error" hx-swap="innerHTML" hx-on::after-request="this.reset()">
					<h1 class="text-2xl font-bold">Login</h1>
					<div id="form-error" class="text-red-500"></div>
					<div>
						<label
							for="email-address-icon"
							class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
						>Your Email</label>
						<div class="relative">
							<div class="absolute inset-y-0 start-0 flex items-center ps-3.5 pointer-events-none">
								<svg class="w-4 h-4 text-gray-500 dark:text-gray-400" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 16">
									<path d="m10.036 8.278 9.258-7.79A1.979 1.979 0 0 0 18 0H2A1.987 1.987 0 0 0 .641.541l9.395 7.737Z"></path>
									<path d="M11.241 9.817c-.36.275-.801.425-1.255.427-.428 0-.845-.138-1.187-.395L0 2.6V14a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V2.5l-8.759 7.317Z"></path>
								</svg>
							</div>
							<input
								type="email"
								name="email"
								value={ props.Form.Email }
								required
								id="email-address-icon"
								class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full ps-10 p-2.5  dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
								placeholder="name@example.com"
							/>
						</div>
					</div>
					<div>
						<label
							for="password-icon"
							class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
						>Your Password</label>
						<div class="relative">
							<div class="absolute inset-y-0 start-0 flex items-center ps-3.5 pointer-events-none">
								<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="w-4 h-4 opacity-70"><path fill-rule="evenodd" d="M14 6a4 4 0 0 1-4.899 3.899l-1.955 1.955a.5.5 0 0 1-.353.146H5v1.5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1-.5-.5v-2.293a.5.5 0 0 1 .146-.353l3.955-3.955A4 4 0 1 1 14 6Zm-4-2a.75.75 0 0 0 0 1.5.5.5 0 0 1 .5.5.75.75 0 0 0 1.5 0 2 2 0 0 0-2-2Z" clip-rule="evenodd"></path></svg>
							</div>
							<input
								type="password"
								name="password"
								required
								id="password-icon"
								class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full ps-10 p-2.5  dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
								placeholder="password"
							/>
						</div>
					</div>
					<div class="flex justify-end w-full">
						<button
							type="submit"
							data-loading-disable
							class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
						>Submit</button>
					</div>
				</form>
			</div>
		</div>
	}
}
