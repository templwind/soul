package account

import (
	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/date"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

templ AccountDetail(e echo.Context, cfg *config.Config, account *models.Account, primaryUser *models.User) {
	<div class="w-full antialiased">
		<div>
			<h2 class="py-2 text-xl font-semibold">Account Details</h2>
			<div class="w-full">
				<div class="text-slate-900 divide-y divide-slate-200 dark:text-white dark:divide-slate-700">
					<h4 class="mb-1 text-slate-500 dark:text-slate-400">Company Name</h4>
					<p class="font-semibold">{ types.NewStringFromNull(account.CompanyName) }</p>
					<h4 class="mb-1 text-slate-500 dark:text-slate-400">Address</h4>
					<p class="font-semibold">
						if account.Address1.Valid  && !account.Address2.Valid {
							{ types.NewStringFromNull(account.Address1) }
						}
						if account.Address2.Valid {
							{ types.NewStringFromNull(account.Address1) + ", " + types.NewStringFromNull(account.Address2) }
						}
						<br/>
						{ types.NewStringFromNull(account.City) }, { types.NewStringFromNull(account.StateProvince) } { types.NewStringFromNull(account.PostalCode) }
					</p>
					<h4 class="mb-1 text-slate-500 dark:text-slate-400">Phone</h4>
					<p class="font-semibold">{ utils.FormatPhone(types.NewStringFromNull(account.Phone), types.NewStringFromNull(account.Country)) }</p>
					<h4 class="mb-1 text-slate-500 dark:text-slate-400">Account Created</h4>
					<p class="font-semibold">{ date.Format(date.StringToTime(account.CreatedAt), "l, F jS, Y"  ) }</p>
					<h4 class="mb-1 text-slate-500 dark:text-slate-400 flex flex-col sm:flex-row justify-between items-baseline">
						Primary User
						<button class="inline-flex text-sm font-normal text-blue-600 underline underline-offset-4 decoration-2">Change</button>
					</h4>
					<p class="font-semibold">{ primaryUser.Name }<br/>{ primaryUser.Email }</p>
				</div>
			</div>
		</div>
		// <hr class="mt-4 mb-8"/>
		// <div class="mb-8">
		// 	<h2 class="py-2 text-xl font-semibold">Delete Account</h2>
		// 	<p class="mt-4 inline-flex items-center rounded-full bg-rose-100 px-4 py-1 text-rose-600">
		// 		<svg xmlns="http://www.w3.org/2000/svg" class="mr-2 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
		// 			<path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path>
		// 		</svg>
		// 		Account Deletion is Permanent
		// 	</p>
		// 	<div class="mt-4 prose">
		// 		<p>By proceeding with the account deletion, you acknowledge and accept the following:</p>
		// 		<ul>
		// 			<li><span class="font-semibold">Permanent Deletion:</span> All your account data will be permanently deleted.</li>
		// 			<li><span class="font-semibold">No Recovery:</span> This action is irreversible. Once deleted, your account and its data cannot be restored.</li>
		// 			<li><span class="font-semibold">Immediate Effect:</span> You will immediately lose access to your account and all associated data.</li>
		// 		</ul>
		// 		<p>If you are certain you want to delete your account, please confirm your decision.</p>
		// 		<button class="ml-auto text-sm font-semibold text-rose-600 underline underline-offset-4 decoration-2">Delete my account</button>
		// 	</div>
		// </div>
	</div>
}
