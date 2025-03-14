<script lang="ts">
	import { ChevronLeft, EllipsisVertical, Settings, CreditCard, LogOut, User } from 'lucide-svelte';
	import type { HeaderProps } from '$lib/types/headerprops';
	import { page } from '$app/state';
	import { userStore } from '$lib/user.store';
	import { slide } from 'svelte/transition';
	import type { Link } from '$lib/types/navigation';

	const showSidebar = $derived(page.data.showSidebar ?? true);
	const { headerProps, children } = $props<{ headerProps: HeaderProps; children: any }>();

	let currentPath = $state('');
	let dropdownMenu: Link[] = $state([]);
	// State for dropdown menu
	let isDropdownOpen = $state(false);

	// Toggle dropdown menu
	function toggleDropdown() {
		isDropdownOpen = !isDropdownOpen;
	}

	// Close dropdown when clicking outside
	function handleClickOutside(event: MouseEvent) {
		const target = event.target as HTMLElement;
		const dropdown = document.getElementById('user-dropdown');
		const avatar = document.getElementById('user-avatar');

		if (dropdown && avatar && !dropdown.contains(target) && !avatar.contains(target)) {
			isDropdownOpen = false;
		}
	}

	// Add event listener for clicks outside dropdown
	$effect(() => {
		currentPath = page.url.pathname;

		dropdownMenu = [
			{
				title: 'Profile',
				href: '/studio/profile',
				icon: User,
				className: currentPath.includes('/studio/profile') ? 'menu-active' : ''
			},
			{
				title: 'Settings',
				href: '/studio/settings',
				icon: Settings,
				className: currentPath.includes('/studio/settings') ? 'menu-active' : ''
			},
			{
				title: 'Billing',
				href: '/studio/billing',
				icon: CreditCard,
				className: currentPath.includes('/studio/billing') ? 'menu-active' : ''
			}
		];

		if (isDropdownOpen) {
			document.addEventListener('click', handleClickOutside);
		} else {
			document.removeEventListener('click', handleClickOutside);
		}

		return () => {
			document.removeEventListener('click', handleClickOutside);
		};
	});

	// $effect(() => {
	// 	console.log(
	// 		'initials:',
	// 		(userStore?.getFirstName()?.charAt(0) || '') + (userStore?.getLastName()?.charAt(0) || '')
	// 	);
	// });
</script>

<div class="mb-16">
	<div
		class="fixed z-10 top-0 right-0 flex items-center justify-between w-auto px-4 shadow-sm navbar bg-base-100 text-base-content transition-all duration-300 ease-in-out {showSidebar
			? 'left-0 lg:left-60'
			: 'left-0'}"
	>
		{#if headerProps?.backUrl}
			<div class="shrink">
				<!-- Left icon container -->
				<a href={headerProps.backUrl} class="mx-0 btn btn-ghost btn-square">
					<ChevronLeft />
				</a>
			</div>
			<h2 class="flex-1 min-w-0 px-4 overflow-hidden text-base font-bold">
				<!-- Center title -->
				<span class="block truncate">{headerProps?.backTitle}</span>
			</h2>
		{:else}
			{#if headerProps?.brandLogo}
				{@const Component = headerProps.brandLogo}
				<div class="shrink">
					<a href={headerProps.brandLink} class="mx-0 btn btn-ghost btn-square">
						<Component class={headerProps.brandLogoClassName} />
					</a>
				</div>
			{/if}
			<div class="flex-1 min-w-0 px-4 overflow-hidden text-base font-bold">
				<a
					href={headerProps?.brandLink}
					class="pl-2 text-lg font-bold truncate sm:pl-0 md:text-2xl"
				>
					{#if headerProps?.brandName}
						{headerProps.brandName}
					{/if}
				</a>
			</div>
		{/if}

		<div class="shrink">
			{#if headerProps?.actionsMenu && headerProps?.actionsMenu?.length > 0}
				{#each headerProps.actionsMenu as action}
					{#if action.href}
						<a href={action.href} class="mx-0 btn {action.className}">
							{#if action.icon}
								{@const IconComponent = action.icon}
								<IconComponent class={action.iconClassName} />
							{/if}
							{action.label}
						</a>
					{:else}
						<button class="mx-0 btn {action.className}">
							{#if action.icon}
								{@const IconComponent = action.icon}
								<IconComponent class={action.iconClassName} />
							{:else}
								<EllipsisVertical class={action.iconClassName} />
							{/if}
						</button>
					{/if}
				{/each}
			{/if}
			{#if userStore.isAuthenticated()}
				<div class="dropdown dropdown-end">
					<div
						tabindex="0"
						role="button"
						class="cursor-pointer avatar avatar-placeholder"
						aria-haspopup="true"
					>
						<div class="rounded-full w-9 sm:w-10 bg-neutral text-neutral-content">
							<span
								>{(userStore?.getFirstName()?.charAt(0) || '') +
									(userStore?.getLastName()?.charAt(0) || '')}</span
							>
						</div>
					</div>

					<!-- Dropdown menu -->
					<ul
						tabindex="0"
						class="z-20 p-2 mt-2 space-y-2 shadow-lg dropdown-content menu bg-base-100 rounded-box w-52"
						role="menu"
						aria-orientation="vertical"
					>
						{#each dropdownMenu as item}
							<li>
								<a href={item.href} class="flex items-center {item.className}" role="menuitem">
									{#if item.icon}
										<item.icon class="w-4 h-4" />
									{/if}
									{item.title}
								</a>
							</li>
						{/each}

						<li class="pt-2 border-t border-base-300">
							<a href="/auth/logout" class="flex items-center text-error" role="menuitem">
								<LogOut class="w-4 h-4" />
								Logout
							</a>
						</li>
					</ul>
				</div>
			{/if}
		</div>

		{#if headerProps?.showDrawer}
			<div class="flex-none lg:hidden">
				<label for="my-drawer" class="pr-2 sm:pr-0 btn btn-square drawer-button">
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
		{/if}
	</div>
</div>
