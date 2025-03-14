<script lang="ts">
	let { children } = $props();
</script>

<div class="flex items-center justify-center w-full h-screen">
	<div class="w-full max-w-md px-4">
		{@render children()}
	</div>
</div>
