<script lang="ts">
	import { onMount, onDestroy } from 'svelte';

	// Set duration (in hours) from current time
	const props: { hoursFromNow?: number } = $props();
	const hoursFromNow = props.hoursFromNow ?? 47;

	// Use $state for reactivity in Svelte 5
	let days = $state(0);
	let hours = $state(0);
	let minutes = $state(0);
	let seconds = $state(0);
	let intervalId: ReturnType<typeof setInterval>;

	// Set end time to next week at midnight MST
	const endTime = new Date();
	endTime.setDate(endTime.getDate() + 7); // Add 7 days
	// Set to midnight MST (UTC-7)
	endTime.setHours(7, 0, 0, 0); // 7 UTC = midnight MST

	function updateCountdown() {
		const now = new Date().getTime();
		const distance = endTime.getTime() - now;

		// Add check for when countdown ends
		if (distance < 0) {
			days = hours = minutes = seconds = 0;
			if (intervalId) clearInterval(intervalId);
			return;
		}

		days = Math.floor(distance / (1000 * 60 * 60 * 24));
		hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
		minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
		seconds = Math.floor((distance % (1000 * 60)) / 1000);
	}

	onMount(() => {
		updateCountdown();
		intervalId = setInterval(updateCountdown, 1000);
	});

	onDestroy(() => {
		if (intervalId) clearInterval(intervalId);
	});
</script>

<div class="grid grid-flow-col gap-5 text-center auto-cols-max">
	<div class="flex flex-col p-2 bg-neutral rounded-box text-neutral-content">
		<span class="font-mono text-5xl countdown">
			<span style="--value:{days};"></span>
		</span>
		days
	</div>
	<div class="flex flex-col p-2 bg-neutral rounded-box text-neutral-content">
		<span class="font-mono text-5xl countdown">
			<span style="--value:{hours};"></span>
		</span>
		hours
	</div>
	<div class="flex flex-col p-2 bg-neutral rounded-box text-neutral-content">
		<span class="font-mono text-5xl countdown">
			<span style="--value:{minutes};"></span>
		</span>
		min
	</div>
	<div class="flex flex-col p-2 bg-neutral rounded-box text-neutral-content">
		<span class="font-mono text-5xl countdown">
			<span style="--value:{seconds};"></span>
		</span>
		sec
	</div>
</div>
