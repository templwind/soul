export type OverageRates = {
    growth: {
        monthly: { newSubscriber: number, accountSubscriber: number },
        yearly: { newSubscriber: number, accountSubscriber: number }
    },
    growthPlus: {
        monthly: { newSubscriber: number, accountSubscriber: number },
        yearly: { newSubscriber: number, accountSubscriber: number }
    }
};

// Constants for billing model
export const BLOCK_SIZE = 100; // Number of subscribers per billing block
export const FREE_LIMIT = 25; // Free plan subscriber limit
export const OVERAGE_PERCENTAGE = 0.1; // 10% buffer before charging for the next block

// Define overage rates for each plan
export const overageRates: OverageRates = {
    growth: {
        monthly: {
            newSubscriber: 3, // $0.03 per additional new subscriber, billed in increments of 100
            accountSubscriber: 10 // $0.10 per 1000 subscribers over the account limit
        },
        yearly: {
            newSubscriber: 3, // $0.03 per additional new subscriber, billed in increments of 100
            accountSubscriber: 10 // $0.10 per 1000 subscribers over the account limit
        }
    },
    growthPlus: {
        monthly: {
            newSubscriber: 4, // $0.04 per additional new subscriber, billed in increments of 100
            accountSubscriber: 10 // $0.10 per 1000 subscribers over the account limit
        },
        yearly: {
            newSubscriber: 4, // $0.04 per additional new subscriber, billed in increments of 100
            accountSubscriber: 10 // $0.10 per 1000 subscribers over the account limit
        }
    }
};

export type SubscriberTier = {
    subscribers: number;                   // Monthly new subscriber limit
    monthlyPrice: number;                  // Price in cents
    yearlyPrice: number;                   // Price in cents
    overagePricePerSubscriber?: number;    // Price in cents per additional new subscriber, billed in increments of 100
    includedSubscriberLimit?: number;      // Total subscribers included in the account for free
    accountOveragePricePerThousand?: number; // Price in cents per 1000 subscribers over the account limit
};

export type PlanTier = {
    name: string;
    description: string;
    baseFeatures: string[];
    subscriberTiers: Record<string, SubscriberTier>;
    leadMagnetTypes: string[];    // Types of lead magnets available
    analytics: string;            // Level of analytics
    brandingRemoved: boolean;     // Whether branding is removed
    focusCharacterLimit: number;  // Character limit for focus field
    audienceCharacterLimit: number; // Character limit for audience field
};

// Yearly discount factor (2 months free = 10/12 = 0.8333...)
export const yearlyMonthsFactor = 10 / 12; // Pay for 10 months, get 12

export enum planName {
    free = 'FREE',
    growth = 'GROWTH',
    growthPlus = 'GROWTH_PLUS'
}

export const pricingData: Record<string, PlanTier> = {
    [planName.free]: {
        name: planName.free,
        description: 'Grow your email list with plans designed for your success as a content creator or influencer. Perfect for trying GoSha.re',
        baseFeatures: [
            '5 shares per month',
            '10 lifetime shares cap',
            'Basic analytics',
            '250 character audience limit',
            '1,000 character focus limit'
        ],
        subscriberTiers: {
            '25': {
                subscribers: 25,
                monthlyPrice: 0,
                yearlyPrice: 0,
                includedSubscriberLimit: 1000 // Total subscribers included in account
            }
        },
        leadMagnetTypes: ['Guide', 'Checklist'],
        analytics: 'Basic',
        brandingRemoved: false,
        focusCharacterLimit: 1000,
        audienceCharacterLimit: 250
    },
    [planName.growth]: {
        name: planName.growth,
        description: 'Grow your email list with plans designed for your success as a content creator or influencer. For growing creators with a budding audience',
        baseFeatures: [
            '10 shares per month',
            'No lifetime shares cap',
            'Branding removed',
            'In-depth analytics',
            'Zapier integration',
            '500 character audience limit',
            '5,000 character focus limit'
        ],
        subscriberTiers: {
            'base': {
                subscribers: 100,
                monthlyPrice: 2000, // $20/month
                yearlyPrice: 20000, // $200/year (10 months for the price of 12)
                overagePricePerSubscriber: 3, // $0.03 per additional new subscriber, billed in increments of 100
                includedSubscriberLimit: 25000, // Total subscribers included in account for free
                accountOveragePricePerThousand: 10 // $0.10 per 1000 subscribers over the account limit
            }
        },
        leadMagnetTypes: ['Guide', 'Checklist'], // leadMagnetTypes: ['Guide', 'Checklist', 'Quiz'],
        analytics: 'In-depth',
        brandingRemoved: true,
        focusCharacterLimit: 5000, // Corrected to match image
        audienceCharacterLimit: 500 // Corrected to match image
    },
    [planName.growthPlus]: {
        name: planName.growthPlus,
        description: 'Grow your email list with plans designed for your success as a content creator or influencer. For power users building their audience',
        baseFeatures: [
            '30 shares per month',
            'No lifetime shares cap',
            'Branding removed',
            'In-depth analytics',
            'Zapier integration',
            'Mailchimp integration',
            'API access & Webhooks',
            '1,000 character audience limit',
            '10,000 character focus limit'
        ],
        subscriberTiers: {
            'base': {
                subscribers: 1000,
                monthlyPrice: 4000, // $40/month
                yearlyPrice: 40000, // $400/year (10 months for the price of 12)
                overagePricePerSubscriber: 4, // $0.04 per additional new subscriber, billed in increments of 100
                includedSubscriberLimit: 50000, // Total subscribers included in account for free
                accountOveragePricePerThousand: 10 // $0.10 per 1000 subscribers over the account limit
            }
        },
        leadMagnetTypes: ['Guide', 'Checklist'],// leadMagnetTypes: ['Guide', 'Checklist', 'Quiz', 'Video', 'Audio'],
        analytics: 'Comprehensive',
        brandingRemoved: true,
        focusCharacterLimit: 10000,
        audienceCharacterLimit: 1000
    }
};