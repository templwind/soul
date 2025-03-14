<script lang="ts">
	import { Check } from 'lucide-svelte';
	import { planName, type OverageRates } from '$lib/pricing';
	import { onMount } from 'svelte';

	const props = $props();

	// Destructure data from the page load function with fallbacks
	const {
		isAnnual: initialIsAnnual = false,
		overageRates = {} as OverageRates,
		subscriberTierOptions = [],
		planTypes = [],
		pricingData = {} // Get pricingData from props instead of importing it
	} = props.data;

	// Reactive Svelte code for pricing page
	let isAnnual = $state(initialIsAnnual); // Default to monthly billing

	// Subscriber slider variables
	let subscriberSliderValue = $state(25); // Default to Free plan limit
	let slider: HTMLInputElement | null = $state(null);
	let valueBox: HTMLDivElement | null = $state(null);
	let resizeTimeout: number | null = $state(null);

	// Toggle between monthly and yearly billing
	function toggleInterval() {
		isAnnual = !isAnnual;
		console.log('Billing interval changed to:', isAnnual ? 'annual' : 'monthly');
	}

	onMount(() => {
		// Set initial slider value to 25 (the default Free plan limit)
		subscriberSliderValue = 25;

		// Add initial position update for the value box
		setTimeout(updateValueBoxPosition);

		// Add resize listener to reposition on window resize with debounce
		const handleResize = () => {
			if (resizeTimeout) {
				window.clearTimeout(resizeTimeout);
			}
			resizeTimeout = window.setTimeout(() => {
				updateValueBoxPosition();
				resizeTimeout = null;
			});
		};

		window.addEventListener('resize', handleResize);

		// Cleanup
		return () => {
			window.removeEventListener('resize', handleResize);
			if (resizeTimeout) {
				window.clearTimeout(resizeTimeout);
			}
		};
	});

	// Format subscriber count for display
	function formatSubscriberCount(count: number): string {
		if (count >= 1000) {
			// Remove decimal places, just show whole numbers with 'k'
			return Math.floor(count / 1000) + 'k';
		}
		return count.toString();
	}

	// Function to update the value box position
	function updateValueBoxPosition() {
		if (!slider || !valueBox) return;

		// Get the slider's bounding rectangle
		const sliderRect = slider.getBoundingClientRect();

		// Get the current slider value and convert to percentage
		const sliderIndex = parseInt(slider.value);
		const sliderMaxIndex = parseInt(slider.max);
		const percentage = sliderIndex / sliderMaxIndex;

		// Simple calculation with linear correction
		// This accounts for the fact that the thumb doesn't move across the full width
		// The correction factor (0.97) slightly reduces the effective width to match actual thumb movement
		const thumbPosition = percentage * sliderRect.width * 0.97 + 10;

		// Position the value box directly above the thumb
		valueBox.style.left = `${thumbPosition}px`;
	}

	// Update slider value
	function updateSliderValue(index: number) {
		if (index >= 0 && index < subscriberTierOptions.length) {
			const newValue = subscriberTierOptions[index];
			if (subscriberSliderValue !== newValue) {
				subscriberSliderValue = newValue;
				updateValueBoxPosition();
			}
		}
	}

	// Function to get plan system name for calculations
	function getPlanSystemName(planType: string): string {
		return planType.toLowerCase().replace(' ', '_');
	}

	function calculateEstimatedPrice(planType: string, subscriberCount: number): string {
		// Check if this is the maximum subscriber count
		if (subscriberCount === subscriberTierOptions[subscriberTierOptions.length - 1]) {
			return 'Contact us';
		}

		// Free plan always returns $0
		if (planType === 'free') {
			return '$0';
		}

		// DIRECT CALCULATION APPROACH

		// First calculate the monthly price correctly
		const planTypeKey = Object.values(planName).find((p) => getPlanSystemName(p) === planType);
		if (!planTypeKey) return '$0';

		const planData = pricingData[planTypeKey];
		if (!planData) return '$0';

		const tierValues = Object.values(planData.subscriberTiers)[0] as any;

		// Calculate monthly price
		const monthlyBasePrice = tierValues.monthlyPrice / 100;
		const includedSubscribers = parseInt(tierValues.subscribers);

		let monthlyOverageRate = 0;
		if (overageRates[planType] && overageRates[planType].monthly) {
			monthlyOverageRate = overageRates[planType].monthly.newSubscriber;
		}

		let monthlyPrice = monthlyBasePrice;
		if (subscriberCount > includedSubscribers) {
			const extraSubscribers = subscriberCount - includedSubscribers;
			const overageBlocks = Math.ceil(extraSubscribers / 100);
			const overageAmount = overageBlocks * 100 * monthlyOverageRate;
			monthlyPrice += overageAmount;
		}

		// If monthly billing, return the monthly price
		if (!isAnnual) {
			return `$${monthlyPrice.toFixed(0)}/mo`;
		}

		// For annual billing, apply a 16.67% discount (2 months free out of 12)
		const annualDiscount = 0.8333; // 10/12 = ~0.8333
		const discountedMonthlyPrice = monthlyPrice * annualDiscount;

		return `$${discountedMonthlyPrice.toFixed(0)}/mo`;
	}

	// Function to determine if a plan is recommended based on the slider value
	function isRecommendedPlan(planType: string): boolean {
		if (!subscriberSliderValue) return planType === 'free'; // Default to Free plan

		// Get the free plan's subscriber limit
		const freeTier = Object.values(pricingData[planName.free].subscriberTiers)[0] as any;
		const freeLimit = parseInt(freeTier.subscribers);

		// If subscriber count is within free plan limit
		if (subscriberSliderValue <= freeLimit) {
			return planType === 'free';
		}

		// Get the Growth Plus threshold (default to 5000 if not specified)
		const growthPlusThreshold = 5000;

		// If subscriber count is high, Growth Plus is recommended
		if (subscriberSliderValue >= growthPlusThreshold) {
			return planType === 'growth_plus';
		}

		// Otherwise, Growth plan is recommended (default)
		return planType === 'growth';
	}

	// Check if Free plan should be disabled
	function isFreePlanDisabled(): boolean {
		if (!subscriberSliderValue) return false;

		// Get the free plan's subscriber limit from pricing data
		const freeTier = Object.values(pricingData[planName.free].subscriberTiers)[0] as any;
		const freeLimit = parseInt(freeTier.subscribers);

		// Free plan is disabled if subscriber count exceeds free limit
		return subscriberSliderValue > freeLimit;
	}
</script>

<div class="min-h-screen bg-base-100">
	<!-- Hero Section with Background -->
	<div class="relative overflow-hidden bg-base-200">
		<div class="absolute inset-0 opacity-10">
			<div
				class="absolute inset-0 transform -skew-y-12 bg-gradient-to-r from-primary to-secondary"
			></div>
		</div>

		<!-- Pricing Header -->
		<div class="relative px-4 py-24 text-center">
			<h1 class="max-w-3xl mx-auto mb-4 text-5xl font-extrabold">Simple Pricing for Creators</h1>
			<p class="max-w-xl mx-auto mb-8 text-xl text-base-content/70">
				Grow your email list with plans designed for your success.
			</p>

			<!-- Billing Toggle -->
			<div
				class="inline-flex items-center justify-center gap-4 p-1 px-2 mx-auto mb-12 font-bold rounded-xl bg-base-100"
			>
				<span class={!isAnnual ? 'text-primary' : 'text-base-content/70'}>Monthly</span>
				<input
					type="checkbox"
					class="toggle toggle-primary"
					checked={isAnnual}
					onchange={toggleInterval}
				/>
				<span class={isAnnual ? 'text-primary' : 'text-base-content/70'}>
					Annual <span class="px-2 py-1 ml-1 text-xs rounded-full bg-primary/10 text-primary"
						>Save 2 months</span
					>
				</span>
			</div>

			<!-- Subscriber Slider -->
			{#if subscriberTierOptions.length > 0}
				<div
					class="max-w-3xl p-6 mx-auto mb-12 border rounded-lg shadow-sm border-base-300 bg-base-100"
				>
					<div class="relative">
						<!-- Slider container with relative positioning -->
						<div class="relative mt-8">
							<!-- Floating value box -->
							<div
								bind:this={valueBox}
								class="absolute top-[-40px] px-2 py-1 text-sm font-medium rounded-md {subscriberSliderValue ===
								subscriberTierOptions[subscriberTierOptions.length - 1]
									? 'bg-secondary text-secondary-content'
									: 'bg-primary text-primary-content'}"
								style="transform: translateX(-50%); min-width: 40px; text-align: center; pointer-events: none;"
							>
								{subscriberSliderValue === subscriberTierOptions[subscriberTierOptions.length - 1]
									? 'Max'
									: formatSubscriberCount(subscriberSliderValue)}
								<div
									class="absolute left-1/2 bottom-[-6px] w-3 h-3 {subscriberSliderValue ===
									subscriberTierOptions[subscriberTierOptions.length - 1]
										? 'bg-secondary'
										: 'bg-primary'} transform rotate-45 -translate-x-1/2"
								></div>
							</div>

							<!-- The slider -->
							<input
								bind:this={slider}
								type="range"
								min="0"
								max={subscriberTierOptions.length - 1}
								value={subscriberTierOptions.indexOf(subscriberSliderValue)}
								class="w-full {subscriberSliderValue ===
								subscriberTierOptions[subscriberTierOptions.length - 1]
									? 'range-secondary'
									: 'range-primary'} range"
								oninput={(e) => {
									const index = parseInt(e.currentTarget.value);
									updateSliderValue(index);
									updateValueBoxPosition();
								}}
								onchange={(e) => {
									updateValueBoxPosition();
								}}
							/>

							<!-- Min/Max labels -->
							<div class="flex justify-between mt-2 text-sm text-base-content/70">
								<span>0</span>
								<span
									>{formatSubscriberCount(
										subscriberTierOptions[subscriberTierOptions.length - 1]
									)}+</span
								>
							</div>
						</div>
					</div>
					<h3 class="mb-4 text-lg font-medium text-center">
						How many new subscribers do you expect per month?
					</h3>
				</div>
			{/if}
		</div>
	</div>
	<!-- Pricing Cards Section -->
	<div class="container px-4 mx-auto -mt-20">
		<div class="grid max-w-6xl grid-cols-1 gap-8 mx-auto md:grid-cols-3">
			{#each planTypes as planType}
				{@const planKey = getPlanSystemName(planType)}
				{@const planData = pricingData[planType]}
				{@const tierValues = Object.values(planData.subscriberTiers)[0]}
				<!-- Plan Card -->
				<div
					class="relative overflow-hidden border-2 shadow-xl card bg-base-100 {isRecommendedPlan(
						planKey
					)
						? 'border-primary'
						: 'border-base-300'}"
				>
					{#if isRecommendedPlan(planKey)}
						<div class="absolute top-0 right-0 px-3 py-1 text-xs font-bold text-white bg-primary">
							RECOMMENDED
						</div>
						<!-- Add a subtle highlight effect -->
						<div class="absolute inset-0 pointer-events-none bg-primary/5"></div>
					{/if}
					{#if planKey === 'free' && isFreePlanDisabled()}
						<div class="absolute top-0 right-0 px-3 py-1 text-xs font-bold text-white bg-base-300">
							Not Available
						</div>
						<!-- Add a subtle highlight effect -->
						<div class="absolute inset-0 pointer-events-none bg-base-300/5"></div>
					{/if}
					<div class="card-body">
						<h2 class="text-xl card-title">{planType}</h2>

						<div class="mt-2 mb-4">
							{#if planKey === 'free'}
								<div class="text-3xl font-bold">$0</div>
								<div class="text-sm text-base-content/70">Forever free</div>
							{:else if subscriberSliderValue === subscriberTierOptions[subscriberTierOptions.length - 1]}
								<div class="text-xl font-bold">
									Over {formatSubscriberCount(subscriberSliderValue)} new subscribers per month?
								</div>
								<div class="mt-1 text-base font-medium text-primary">
									<a href="/contact?request=enterprise-pricing" class="text-primary"
										>Request enterprise pricing</a
									>
								</div>
							{:else}
								<div class="text-3xl font-bold">
									{calculateEstimatedPrice(planKey, subscriberSliderValue)}
									<div class="text-sm text-base-content/70">
										{isAnnual ? 'billed annually' : 'billed monthly'}
									</div>
								</div>
								<div class="text-sm text-base-content/70">
									{#if isAnnual}
										<span class="font-medium text-primary">Save 2 months with annual billing</span>
									{/if}
								</div>
							{/if}
						</div>
						<div class="my-2 divider"></div>
						<ul class="flex-grow mb-6 space-y-2">
							{#each planData.baseFeatures as feature}
								<li class="flex items-start gap-2">
									<Check class="flex-shrink-0 mt-1 size-4 text-success" />
									<span>{feature}</span>
								</li>
							{/each}
						</ul>

						<div class="card-actions">
							<a
								href={planKey === 'free' && isFreePlanDisabled()
									? '#'
									: planKey === 'free'
										? '/auth/register'
										: `/auth/register?plan=${planKey}`}
								class="btn btn-block {isFreePlanDisabled() && planKey === 'free'
									? 'btn-disabled'
									: isRecommendedPlan(planKey)
										? 'btn-primary'
										: 'btn-outline'}"
							>
								{planKey === 'free' && isFreePlanDisabled()
									? 'Not Available'
									: subscriberSliderValue ===
												subscriberTierOptions[subscriberTierOptions.length - 1] &&
										  planKey !== 'free'
										? 'Request Demo'
										: planKey === 'free'
											? 'Start with Free'
											: 'Subscribe Now'}
							</a>
						</div>
					</div>
				</div>
			{/each}
		</div>
	</div>

	<!-- Asterisk note -->
	<div class="container px-4 mx-auto mt-8 text-sm text-center text-base-content/70">
		* See "What happens if I exceed my total subscriber storage limit?" in the FAQ section below
	</div>

	<!-- FAQ Section -->
	<div class="py-24 mt-24 bg-base-200">
		<div class="container px-4 mx-auto">
			<h2 class="mb-2 text-4xl font-bold text-center">Frequently Asked Questions</h2>
			<p class="mb-12 text-xl text-center text-base-content/70">
				Everything you need to know about our pricing and products
			</p>
			<div class="max-w-3xl mx-auto space-y-4">
				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" checked />
					<div class="text-xl font-medium collapse-title">
						What's included in the subscriber limit?
					</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							The subscriber limit includes all new subscribers you acquire within a monthly period.
							We don't count repeat subscribers, so you get the most value from your plan.
						</p>
					</div>
				</div>

				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" />
					<div class="text-xl font-medium collapse-title">How does annual billing work?</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							Annual billing is charged at 10× the monthly rate, giving you two months free compared
							to monthly billing. You can switch between billing periods at any time.
						</p>
					</div>
				</div>

				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" />
					<div class="text-xl font-medium collapse-title">
						Can I upgrade or downgrade at any time?
					</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							Yes! You can change your plan at any time. When upgrading, you'll be charged the
							prorated difference. When downgrading, your new rate will apply at the start of your
							next billing cycle.
						</p>
					</div>
				</div>

				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" />
					<div class="text-xl font-medium collapse-title">
						What happens if I exceed my monthly new subscriber limit?
					</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							We'll notify you when you reach 80% and 100% of your subscriber limit. You'll be
							charged for additional subscribers according to your plan's overage rates, billed in
							increments of 100 subscribers.
						</p>
					</div>
				</div>

				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" />
					<div class="text-xl font-medium collapse-title">
						What happens if I exceed my total subscriber storage limit? *
					</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							We'll bill you $0.10 per 1,000 subscribers over the account limit for storage and
							subscriber management.
						</p>
					</div>
				</div>

				<div class="collapse collapse-plus bg-base-100">
					<input type="radio" name="faq" />
					<div class="text-xl font-medium collapse-title">
						Do you offer custom enterprise solutions?
					</div>
					<div class="collapse-content">
						<p class="text-base-content/70">
							Yes! For businesses with specific needs or higher subscriber requirements (over {formatSubscriberCount(
								subscriberTierOptions[subscriberTierOptions.length - 1]
							)}
							subscribers per month), please contact our sales team for a custom solution tailored to
							your requirements.
						</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<style>
	/* Custom styling for the range input */
	input[type='range'].range-primary {
		--thumb-width: 16px;
		position: relative;
	}
</style>
