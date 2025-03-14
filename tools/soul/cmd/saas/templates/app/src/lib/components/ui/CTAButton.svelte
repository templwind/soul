<script lang="ts">
	import { ChevronRight } from 'lucide-svelte';
</script>

<div class="flex flex-col justify-center gap-4 sm:flex-row">
	<a
		href="/auth/register"
		class="relative gap-2 py-8 transition-transform duration-200 shadow-lg pr-14 btn btn-primary btn-xl hover:scale-105"
	>
		<div class="flex flex-col items-center">
			<span class="text-xl font-bold">Start Your Funnel-In-Bio</span>
			<span class="text-xs font-normal opacity-90"
				>Forever-Free Account • No Credit Card Required</span
			>
		</div>
		<ChevronRight size={48} class="absolute right-0" />
		<ChevronRight size={48} class="absolute right-2" />
	</a>
</div>
