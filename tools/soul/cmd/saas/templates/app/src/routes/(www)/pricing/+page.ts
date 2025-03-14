import type { PageLoad } from './$types';
import { pricingData, planName, yearlyMonthsFactor } from '$lib/pricing';
import type { SubscriptionPlan } from '$lib/api/models';

export const load: PageLoad = async ({ fetch }) => {
    const subscriberTierOptions = [
        0, 25, 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 500, 600, 700, 800, 900, 1000,
        1200, 1400, 1600, 1800, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 6000, 7000, 8000, 9000,
        10000, 15000, 15001
    ];

    // Initialize with a default subscription object to match the upgrade page
    const subscription = { status: 'none', planName: 'Free', billingInterval: 'monthly' };

    // Extract overage rates directly from pricing data
    const overageRates: Record<string, any> = {};

    // Process each plan to enhance features and calculate overage rates
    Object.values(planName).forEach(planType => {
        const planData = pricingData[planType];
        const tierValues = Object.values(planData.subscriberTiers)[0];

        // Add subscriber limit to baseFeatures if it exists
        if (tierValues.includedSubscriberLimit) {
            planData.baseFeatures.push(`Store up to ${tierValues.includedSubscriberLimit.toLocaleString()} total subscribers*`);
        }

        // Add lead magnet types to baseFeatures
        if (planData.leadMagnetTypes && planData.leadMagnetTypes.length > 0) {
            planData.baseFeatures.push(`Lead magnet types: ${planData.leadMagnetTypes.join(', ')}`);
        }

        // Calculate overage rates
        const planKey = planType.toLowerCase().replace(' ', '_');

        if (planKey !== 'free') {
            // Calculate monthly overage rates
            const monthlyNewSubscriberOverage = tierValues.overagePricePerSubscriber ? tierValues.overagePricePerSubscriber / 100 : 0;
            const monthlyAccountOverage = tierValues.accountOveragePricePerThousand ? tierValues.accountOveragePricePerThousand / 100 : 0;

            // Calculate yearly overage rates (with discount)
            const yearlyNewSubscriberOverage = monthlyNewSubscriberOverage / yearlyMonthsFactor;
            const yearlyAccountOverage = monthlyAccountOverage / yearlyMonthsFactor;

            // Store the rates
            overageRates[planKey] = {
                monthly: {
                    newSubscriber: monthlyNewSubscriberOverage,
                    accountSubscriber: monthlyAccountOverage
                },
                yearly: {
                    newSubscriber: yearlyNewSubscriberOverage,
                    accountSubscriber: yearlyAccountOverage
                }
            };
        }
    });

    return {
        subscription,
        isAnnual: false, // Default to monthly billing
        overageRates,
        subscriberTierOptions,
        planTypes: Object.values(planName), // Pass only the unique plan names to the frontend
        pricingData,
        showSidebar: false
    };
}; 