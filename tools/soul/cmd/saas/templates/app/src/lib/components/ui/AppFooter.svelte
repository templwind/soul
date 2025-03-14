<script lang="ts">
	import type { Link } from '$lib/types/navigation';

	const { links } = $props<{
		links: Link[];
	}>();
</script>

<div class="border-t dock dock-md bg-base-100 border-base-300">
	{#each links as link}
		{#if link.isButton}
			<button class={link.className} onclick={link.onClick} aria-label="Toggle settings menu">
				{#if link.icon}
					{@const Icon = link.icon}
					<Icon />
				{/if}
				<span class="dock-label {link.titleClass || ''}">{link.title}</span>
			</button>
		{:else}
			<a class={link.className} href={link.href}>
				{#if link.icon}
					{@const Icon = link.icon}
					<Icon />
				{/if}
				<span class="dock-label {link.titleClass || ''}">{link.title}</span>
			</a>
		{/if}
	{/each}
</div>
