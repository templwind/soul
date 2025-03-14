import { error } from '@sveltejs/kit';
import { browser } from '$app/environment';

export const prerender = false;
export const ssr = false;

export function load({ params }) {
    if (browser) {
        const validKinds = ['expired', 'invalid', 'not-found', 'verified', 'failed', 'success'];
        const { kind } = params;

        if (!validKinds.includes(kind)) {
            throw error(404, 'Invalid verification status');
        }

        return {
            kind
        };
    }
}
