package account

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/models"

	"github.com/labstack/echo/v4"
)

templ UserForm(e echo.Context, cfg *config.Config, user *models.User) {
	<form
		class="pb-4"
		hx-post="/app/settings/account"
		hx-target="#user-form-error"
		hx-swap="innerHTML"
	>
		<div id="user-form-error" class="text-red-500"></div>
		<div class="mb-4">
			<label
				for="user-name"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Name</label>
			<input
				type="text"
				name="name"
				value={ user.Name }
				id="user-name"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder="Lot A"
			/>
		</div>
		<div class="mb-4">
			<label
				for="user-email"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Email</label>
			<input
				type="email"
				name="email"
				value={ user.Email }
				id="user-email"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder=""
			/>
		</div>
		<div class="flex justify-end">
			<button
				type="submit"
				data-loading-disable
				class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm w-full sm:w-auto px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
			>Update Account</button>
		</div>
	</form>
}
