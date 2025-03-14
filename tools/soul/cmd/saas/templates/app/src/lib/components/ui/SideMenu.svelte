<script lang="ts">
	import Self from './SideMenu.svelte';
	import type { Link } from '$lib/types/navigation';
	let { links, footerLinks = [] }: { links: Link[]; footerLinks?: Link[] } = $props();
</script>

<div class="flex flex-col justify-between h-full">
	<ul class="w-full px-0 py-0 space-y-2 menu bg-base-200">
		{#each links as link}
			<li class={link.liClassName}>
				{#if link.isButton}
					<!-- svelte-ignore a11y_label_has_associated_control -->
					<label class={link.className} {...link.attributes}>
						{#if link.icon}
							<link.icon />
						{/if}
						{link.title}
					</label>
				{:else}
					<a href={link.href} class={link.className}>
						{#if link.icon}
							<link.icon />
						{/if}
						{link.title}
					</a>
				{/if}
				{#if link.children && link.children.length > 0}
					<ul>
						<Self links={link.children} />
					</ul>
				{/if}
			</li>
		{/each}
	</ul>

	{#if footerLinks.length > 0}
		<ul class="w-full px-0 py-0 mb-3 space-y-2 menu bg-base-200">
			{#each footerLinks as link}
				<li class={link.liClassName}>
					{#if link.isButton}
						<!-- svelte-ignore a11y_label_has_associated_control -->
						<label class={link.className} {...link.attributes}>
							{#if link.icon}
								<link.icon />
							{/if}
							{link.title}
						</label>
					{:else}
						<a href={link.href} class={link.className}>
							{#if link.icon}
								<link.icon />
							{/if}
							{link.title}
						</a>
					{/if}
					{#if link.children && link.children.length > 0}
						<ul>
							<Self links={link.children} />
						</ul>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</div>
