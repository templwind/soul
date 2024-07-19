package account

import (
	"{{ .ModuleName }}/internal/date"
	"{{ .ModuleName }}/internal/ui/layouts/applayout"
	"{{ .ModuleName }}/internal/templwind/components/appheader"
	"{{ .ModuleName }}/internal/templwind/components/dropdown"

	"github.com/labstack/echo/v4"
)

templ Index(props *Props) {
	@applayout.New(
		applayout.WithTitle("Account"),
		applayout.WithConfig(props.Config),
		applayout.WithEcho(props.Echo),
	) {
		@appheader.New(
			appheader.WithTitle("Account settings"),
		)
		<div
			x-data="{ activeTab: 'account' }"
			class="flex flex-col bg-white border rounded-lg md:flex-row sm:border-none border-slate-300"
		>
			<div class="w-full md:w-1/3 xl:w-1/4 sm:hidden">
				@dropdown.New(dropdown.WithLinks([]dropdown.Link{
					{Title: "Account Information", Click: "activeTab = 'account'"},
					{Title: "User Profile", Click: "activeTab = 'profile'"},
					{Title: "Update Password", Click: "activeTab = 'password'"},
					// {Title: "Two Factor Authentication", Click: "activeTab = 'two_factor_auth'"},
					{Title: "Delete Account", Click: "activeTab = 'delete_account'"},
				}))
			</div>
			<div class="hidden w-full md:w-1/3 xl:w-1/4 sm:block">
				<button
					@click="activeTab = 'account'"
					class="flex flex-col w-full p-8 text-left border-t border-b border-l rounded-tl-lg rounded-tr-lg border-slate-300 md:rounded-tr-none"
					:class=" activeTab === 'account' ? 'bg-white border-r md:border-r-0' : 'bg-slate-200 dark:bg-slate-800 border-r'"
				>
					<span class="text-slate-900">Account Information</span>
					<span class="text-sm text-slate-500">Update your account information.</span>
				</button>
				<button
					@click="activeTab = 'profile'"
					class="flex flex-col w-full p-8 text-left border-b border-l border-slate-300"
					:class=" activeTab === 'profile' ? 'bg-white border-r md:border-r-0' : 'bg-slate-200 dark:bg-slate-800 border-r'"
				>
					<span class="text-slate-900">User Profile</span>
					<span class="text-sm text-slate-500">Update your profile information and email address.</span>
				</button>
				<button
					@click="activeTab = 'password'"
					class="flex flex-col w-full p-8 text-left border-b border-l border-slate-300"
					:class=" activeTab === 'password' ? 'bg-white border-r md:border-r-0' : 'bg-slate-200 dark:bg-slate-800 border-r'"
				>
					<span class="text-slate-900">Update Password</span>
					<span class="text-sm text-slate-500">Ensure your account is using a long, random password to stay secure.</span>
				</button>
				<!--button
					@click="activeTab = 'two_factor_auth'"
					class="flex flex-col w-full p-8 text-left border-b border-l border-slate-300"
					:class=" activeTab === 'two_factor_auth' ? 'bg-white border-r md:border-r-0' : 'bg-slate-200 dark:bg-slate-800 border-r'"
				>
					<span class="text-slate-900">Two Factor Authentication</span>
					<span class="text-sm text-slate-500">Add additional security to your account using two factor authentication.</span>
				</button-->
				<button
					@click="activeTab = 'delete_account'"
					class="flex flex-col w-full p-8 text-left border-b border-l border-slate-300 md:rounded-bl-lg"
					:class=" activeTab === 'delete_account' ? 'bg-white border-r md:border-r-0' : 'bg-slate-200 dark:bg-slate-800 border-r'"
				>
					<span class="text-slate-900">Delete Account</span>
					<span class="text-sm text-slate-500">Permanently delete your account.</span>
				</button>
			</div>
			<div class="flex flex-col items-start justify-start w-full px-4 py-8 rounded-br-lg md:w-2/3 xl:w-3/4 sm:px-0 sm:pl-8 sm:border-t sm:border-r sm:border-b border-slate-300 md:rounded-tr-lg md:rounded-bl-lg">
				<div
					x-show="activeTab === 'account'"
					class="w-full md:w-3/4 xl:w-1/2"
				>
					// @AccountDetail(e, cfg, account, primaryUser)
					@AccountForm(e, cfg, account, primaryUser)
					<hr class="w-full my-8 border-t border-slate-300 dark:border-slate-700"/>
					<div>
						<h4 class="block mb-2 text-sm font-medium text-gray-500 dark:text-white">Account Created</h4>
						<p class="font-semibold">{ date.Format(date.StringToTime(account.CreatedAt), "l, F jS, Y"  ) }</p>
					</div>
				</div>
				<div
					x-show="activeTab === 'profile'"
					class="w-full md:w-3/4 xl:w-1/2"
				>
					@UserForm(e, cfg, primaryUser)
				</div>
				<div
					x-show="activeTab === 'password'"
					class="w-full md:w-3/4 xl:w-1/2"
				>
					@ChangePasswordForm()
				</div>
				<div
					x-show="activeTab === 'two_factor_auth'"
					class="w-full md:w-3/4 xl:w-1/2"
				>
					<p class="text-slate-900">You have not enabled two factor authentication.</p>
					<p class="mt-2 text-sm text-slate-500">When two factor authentication is enabled, you will be prompted for a secure, random token during authentication. You may retrieve this token from your phone's Google Authenticator application.</p>
					<form class="mt-8">
						<div>
							<button class="w-32 bg-primary hover:bg-primary-dark rounded-lg py-1.5 text-slate-200 text-sm uppercase hover:shadow-xl transition duration-150">Enable</button>
						</div>
					</form>
				</div>
				<div
					x-show="activeTab === 'delete_account'"
					class="w-full md:w-3/4 xl:w-1/2"
				>
					<p class="text-sm text-slate-500">Once your account is deleted, all of its resources and data will be permanently deleted.</p>
					<form class="mt-8">
						<div>
							<button class="bg-red-600 hover:bg-red-700 rounded-lg px-8 py-1.5 text-slate-100 text-sm uppercase hover:shadow-xl transition duration-150">Delete Account</button>
						</div>
					</form>
				</div>
			</div>
		</div>
	}
}
