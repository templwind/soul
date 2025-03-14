import type { PageLoad } from './$types';
import { browser } from '$app/environment';
import { api } from '$lib/api';
import { goto } from '$app/navigation';

export const prerender = false;
export const ssr = false;

export const load: PageLoad = async ({ url, fetch }) => {
    if (browser) {
        try {
            const response = await api.VerifyGet(url.searchParams.get('token') as string, { fetch });
            if (response.status === 'success') {
                goto(response.redirectUrl || '/studio');
            }
            // If we get here, there was an error
            return { error: response.message || 'Invalid or expired verification link' };
        } catch (e) {
            return { error: 'Invalid or expired verification link' };
        }
    }
}; 