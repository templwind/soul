package account

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

templ AccountForm(props *Props) {
	<form
		class="pb-4"
		hx-post="/app/settings/account"
		hx-target="#account-form-error"
		hx-swap="innerHTML"
	>
		<div id="account-form-error" class="text-red-500"></div>
		<div class="mb-4">
			<label
				for="account-company-name"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Company Name</label>
			<input
				type="text"
				name="company_name"
				value={ types.NewStringFromNull(props.Account.CompanyName) }
				id="account-company-name"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder="Lot A"
			/>
		</div>
		<div class="mb-4 grid grid-cols-9 gap-4">
			<div class="col-span-6">
				<label
					for="account-address-1"
					class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
				>Address</label>
				<input
					type="text"
					name="address_1"
					value={ types.NewStringFromNull(props.Account.Address1) }
					id="account-address-1"
					required
					class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					placeholder="Street address"
				/>
			</div>
			<div class="col-span-3">
				<label
					for="account-address-2"
					class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
				>Suite / #</label>
				<input
					type="text"
					name="address_2"
					value={ types.NewStringFromNull(props.Account.Address2) }
					id="account-address-2"
					required
					class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					placeholder=""
				/>
			</div>
		</div>
		<div class="mb-4 grid grid-cols-9 gap-4">
			<div class="col-span-4">
				<label
					for="account-city"
					class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
				>City</label>
				<input
					type="text"
					name="city"
					value={ types.NewStringFromNull(props.Account.City) }
					id="account-city"
					required
					class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					placeholder="City"
				/>
			</div>
			<div class="col-span-3">
				<label
					for="account-state-province"
					class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
				>State</label>
				<input
					type="text"
					name="state_province"
					value={ types.NewStringFromNull(props.Account.StateProvince) }
					id="account-state-province"
					required
					class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					placeholder="State / Province"
				/>
			</div>
			<div class="col-span-2">
				<label
					for="account-postal-code"
					class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
				>Zip</label>
				<input
					type="text"
					name="postal_code"
					value={ types.NewStringFromNull(props.Account.PostalCode) }
					id="account-postal-code"
					required
					class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
					placeholder="Zip"
				/>
			</div>
		</div>
		<div class="mb-4">
			<label
				for="account-country"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Country</label>
			<select
				id="account-country"
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
			>
				@getCountryOptions(props.Config, props.Account)
			</select>
		</div>
		<div class="mb-4">
			<label
				for="account-phone"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Phone Number</label>
			<input
				type="text"
				name="phone"
				value={ utils.FormatPhone(types.NewStringFromNull(props.Account.Phone), types.NewStringFromNull(props.Account.Country)) }
				id="account-phone"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder="(555) 555-5555"
			/>
		</div>
		<div class="mb-4">
			<label
				for="account-website"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Website</label>
			<input
				type="text"
				name="text"
				value={ types.NewStringFromNull(props.Account.Website) }
				id="account-website"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder="(555) 555-5555"
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

templ UpdateAccountSuccess() {
	<div
		class="mb-8 bg-green-100 border-t border-b border-green-500 text-green-700 px-4 py-3"
		role="alert"
	>
		<p class="font-bold">Success!</p>
		<p class="text-sm">Account updated successfully.</p>
		<p
			class="text-sm"
			x-data="{ 
			countdown: 3, 
			hide() { this.parent.classList.add('hidden');}, 
			startCountdown() { 
				let interval = setInterval(() => { 
					if (this.countdown > 1) { 
						this.countdown--; 
					} else { 
						this.hide(); 
						clearInterval(interval);
					} 
				}, 1000) 
			} 
		}"
			x-init="startCountdown"
		>
			Redirecting to login page in <span x-text="countdown" class="font-semibold"></span> seconds...
		</p>
	</div>
}
