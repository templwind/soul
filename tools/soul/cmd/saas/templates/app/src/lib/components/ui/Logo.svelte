<script lang="ts">
	export let fancyBrandName: string = '';
	export let words: string[] = [];
	export let colors: string[] = [];
	export let size: string = 'text-2xl'; // default size
</script>

{#if fancyBrandName}
	<div class="text-center">{fancyBrandName}</div>
{/if}

{#if words.length > 0}
	<div class="flex flex-wrap justify-center subpixel-antialiased logo">
		{#each words as word, i}
			<span class="{size} {i > 0 ? '-ml-1' : ''} {colors[i] || ''}">{word}</span>
		{/each}
	</div>
{/if}
