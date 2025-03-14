<script lang="ts">
	import { ChevronRight } from 'lucide-svelte';

	let { children } = $props();

	let theme = $state('corporate');
	let isMenuOpen = $state(false);
	const allowTheming = $state(false);

	const companyName = $state('');
	const CTAText = $state('Get Started');
	const navbarMenu = $state([
		{
			label: 'Home',
			href: '/'
		},
		{
			label: 'Pricing',
			href: '/pricing'
		}
	]);

	const footerLinks = $state({
		company: [
			{
				label: 'About',
				href: '/about'
		},
		{
			label: 'Contact',
			href: '/contact'
			}
		],
		legal: [
			{
				label: 'Terms of use',
				href: '/terms'
			},
			{
				label: 'Privacy policy',
				href: '/privacy'
			},
			{
				label: 'Cookie policy',	
				href: '/cookies'
			}
		],
		social: [
			{
				label: 'X',
				href: 'https://x.com/'
			},
			{
				label: 'Instagram',
				href: 'https://www.instagram.com/'
			},
		]
	});

	

	function applyTheme(node: Document, theme: string) {
		if (!allowTheming) return;
		const html = node.getElementsByTagName('html')[0];
		html.dataset.theme = theme;

		return {
			update(newTheme: string) {
				html.dataset.theme = newTheme;
			},
			destroy() {
				html.removeAttribute('data-theme');
			}
		};
	}

	// $effect(() => {
	// 	console.log('isMenuOpen changed:', isMenuOpen);
	// });
</script>

<svelte:document use:applyTheme={theme} />

<!-- <div
	class="fixed bottom-0 right-0 z-50 w-48 p-4 m-2 font-bold text-center text-black bg-white border-2 border-black rounded-lg"
>
	{theme}
</div> -->

<div class="flex flex-col min-h-screen">
	<!-- Navbar -->
	<nav class="sticky top-0 z-50 navbar bg-base-100">
		<div class="navbar-start">
			<div class="select-none dropdown">
				<button
					tabindex="0"
					aria-label="Toggle menu"
					type="button"
					class="btn btn-ghost lg:hidden"
					onclick={() => {
						// console.log('isMenuOpen', isMenuOpen);
						// isMenuOpen = !isMenuOpen;
					}}
				>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						class="w-5 h-5"
						fill="none"
						viewBox="0 0 24 24"
						stroke="currentColor"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M4 6h16M4 12h8m-8 6h16"
						></path>
					</svg>
				</button>
				{#if isMenuOpen}
					<ul
						class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
					>
						{#each navbarMenu as item}
							<li>
								<a href={item.href}>{item.label}</a>
							</li>
						{/each}
					</ul>
				{/if}
			</div>
			<a href="/" class="px-2 text-2xl antialiased font-semibold tracking-tight"> GoSha.re </a>
		</div>
		<div class="hidden navbar-center lg:flex">
			<ul class="px-1 menu menu-horizontal">
				{#each navbarMenu as item}
					<li>
						<a href={item.href}>{item.label}</a>
					</li>
				{/each}
			</ul>
		</div>
		<div class="navbar-end">
			<a
				href="/auth/register"
				class="relative pr-8 transition-transform duration-200 shadow-lg btn btn-primary hover:scale-105"
			>
				{CTAText}
				<ChevronRight size={24} class="absolute right-0" />
				<ChevronRight size={24} class="absolute right-1.5" />
			</a>
		</div>
	</nav>

	<!-- Page Content -->
	<main class="flex-1">
		{@render children()}
	</main>

	<!-- Footer -->
	<footer class="p-10 footer bg-neutral text-neutral-content">
		<div>
			<span class="footer-title">{companyName}</span>
			{#each footerLinks.company as item}
				<a href={item.href} class="link link-hover">{item.label}</a>
			{/each}
		</div>
		<div>
			<span class="footer-title">Legal</span>
			{#each footerLinks.legal as item}
				<a href={item.href} class="link link-hover">{item.label}</a>
			{/each}
		</div>
		<div>
			<span class="footer-title">Social</span>
			<div class="grid grid-flow-col gap-4">
				{#each footerLinks.social as item}
					<a href={item.href} class="link link-hover">{item.label}</a>
				{/each}
			</div>
		</div>
	</footer>
</div>
