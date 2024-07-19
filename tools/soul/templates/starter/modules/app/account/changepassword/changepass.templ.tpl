package changepassword

templ ChangePasswordForm() {
	<form
		class="pb-4"
		hx-post="/app/settings/account/change-password"
		hx-target="#user-form-response"
		hx-swap="innerHTML"
	>
		<div id="user-form-response"></div>
		<div class="mb-4">
			<label
				for="current-password"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Current Password</label>
			<input
				type="password"
				name="password"
				value=""
				id="current-password"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder=""
			/>
		</div>
		<hr class="my-4 border-gray-200 dark:border-slate-600"/>
		<div class="mb-4">
			<label
				for="user-new-password"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>New Password</label>
			<input
				type="password"
				name="new_password"
				value=""
				id="user-new-password"
				required
				class="bg-slate-50 border border-slate-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5 dark:bg-slate-700 dark:border-slate-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
				placeholder=""
			/>
		</div>
		<div class="mb-4">
			<label
				for="user-confirm-password"
				class="block mb-2 text-sm font-medium text-gray-500 dark:text-white"
			>Repeat New Password</label>
			<input
				type="password"
				name="confirm_password"
				value=""
				id="user-confirm-password"
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
			>Update Password</button>
		</div>
	</form>
}

templ PasswordChangedSuccess() {
	<div
		class="mb-8 bg-green-100 border-t border-b border-green-500 text-green-700 px-4 py-3"
		role="alert"
	>
		<p class="font-bold">Success!</p>
		<p class="text-sm">Password changed successfully.</p>
		<p
			class="text-sm"
			x-data="{ 
			countdown: 5, 
			redirect() { window.location.href = '/login' }, 
			startCountdown() { 
				let interval = setInterval(() => { 
					if (this.countdown > 1) { 
						this.countdown--; 
					} else { 
						this.redirect(); 
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
