<script lang="ts">
	let { children } = $props();
</script>

<div class="flex min-h-screen">
	{@render children()}
</div>
