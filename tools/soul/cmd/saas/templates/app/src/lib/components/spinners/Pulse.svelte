<script lang="ts">
	import type { SpinnerTypes } from './types/spinner.type';
	import { range, durationUnitRegex } from './utils';
	export let color: SpinnerTypes['color'] = '#FF3E00';
	export let unit: SpinnerTypes['unit'] = 'px';
	export let duration: SpinnerTypes['duration'] = '1.5s';
	export let size: SpinnerTypes['size'] = '60';
	export let pause: SpinnerTypes['pause'] = false;
	let durationUnit: string = duration.match(durationUnitRegex)?.[0] ?? 's';
	let durationNum: string = duration.replace(durationUnitRegex, '');
</script>

<div class="wrapper" style="--size: {size}{unit}; --color: {color}; --duration: {duration}">
	{#each range(3, 0) as version}
		<div
			class="cube"
			class:pause-animation={pause}
			style="animation-delay: {version * (+durationNum / 10)}{durationUnit}; left: {version *
				(+size / 3 + +size / 15) +
				unit};"
		></div>
	{/each}
</div>

<style>
	.wrapper {
		position: relative;
		display: flex;
		justify-content: center;
		align-items: center;
		width: var(--size);
		height: calc(var(--size) / 2.5);
	}
	.cube {
		position: absolute;
		top: 0px;
		width: calc(var(--size) / 5);
		height: calc(var(--size) / 2.5);
		background-color: var(--color);
		animation: motion var(--duration) cubic-bezier(0.895, 0.03, 0.685, 0.22) infinite;
	}
	.pause-animation {
		animation-play-state: paused;
	}
	@keyframes motion {
		0% {
			opacity: 1;
		}
		50% {
			opacity: 0;
		}
		100% {
			opacity: 1;
		}
	}
</style>
