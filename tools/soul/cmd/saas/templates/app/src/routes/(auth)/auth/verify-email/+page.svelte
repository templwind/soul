<script lang="ts">
	import Logo from '$lib/components/ui/Logo.svelte';
	import { siteConfig } from '$lib/config';

	const props: {
		data: {
			error: string;
		};
	} = $props();
	let message = $state(props.data.error || 'Verifying your email address...');
</script>

<div class="z-10 flex flex-col flex-1 px-4 py-10 bg-base-100 md:flex-none md:px-28">
	<main class="w-full max-w-md mx-auto sm:px-4 md:w-96 md:max-w-sm md:px-0">
		<div class="flex">
			<a href="/" class="flex flex-row" aria-label="Home">
				{#if siteConfig.logoSvg}
					<Logo fancyBrandName={siteConfig.title} />
					<span class="sr-only">{siteConfig.title}</span>
				{:else if siteConfig.title}
					<h1 class="ml-2 text-2xl font-semibold flex-2">{siteConfig.title}</h1>
				{/if}
			</a>
		</div>

		<div class="mt-20 text-center">
			{#if props.data.error}
				<p class="mt-4 text-error">{message}</p>
				<div class="mt-8">
					<a href="/auth/login" class="btn btn-primary">Back to Login</a>
				</div>
			{:else}
				<div class="loading loading-spinner loading-lg"></div>
				<p class="mt-4 text-base-content">{message}</p>
			{/if}
		</div>
	</main>
</div>
<div class="hidden bg-base-200 sm:contents lg:relative lg:block lg:flex-1"></div>
