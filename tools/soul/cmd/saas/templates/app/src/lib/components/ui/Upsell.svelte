<script lang="ts">
	import { goto } from '$app/navigation';

	function upgrade() {
		goto('/studio/upgrade');
	}
</script>

<div role="alert" class="mb-4 bg-base-300 alert alert-vertical sm:alert-horizontal">
	<svg
		xmlns="http://www.w3.org/2000/svg"
		fill="none"
		viewBox="0 0 24 24"
		class="w-6 h-6 stroke-info shrink-0"
	>
		<path
			stroke-linecap="round"
			stroke-linejoin="round"
			stroke-width="2"
			d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
		></path>
	</svg>
	<div>
		<h3 class="font-bold">You're on the Free Plan!</h3>
		<div class="text-xs">
			<a href="/studio/upgrade" class="link link-primary">Upgrade</a> to unlock more shares and premium
			features.
		</div>
	</div>
	<button class="btn btn-sm btn-secondary" onclick={upgrade}>Upgrade</button>
</div>
