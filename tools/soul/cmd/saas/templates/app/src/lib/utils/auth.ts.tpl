import { getApiUrl } from "$lib/utils";
import { browser } from "$app/environment";
import { api, type CheckResponse } from "$lib/api";
import { goto } from "$app/navigation";
import { userStore } from "$lib/user.store";
// Local storage key for tracking last known auth state
const LAST_AUTH_STATE_KEY = 'las';
// Flag to prevent multiple redirects
let isRedirecting = false;

// We'll use the JWT cookie that's already set by the backend
// This is more secure than localStorage and aligns with the backend implementation

export async function isAuthenticated(fetch: typeof window.fetch): Promise<boolean> {
    // If we're not in a browser, we can't check cookies or localStorage
    if (!browser) return false;

    try {
        // Make a lightweight auth check request to your backend
        // The credentials: 'include' ensures cookies are sent with the request
        const response = await fetch(getApiUrl('auth/check'), {
            credentials: 'include'
        });

        // If the response is successful, update the last known state and return the result
        if (response.ok) {
            const data: CheckResponse = await response.json();
            const isAuth = data.authenticated;

            // Store the last known authentication state
            storeLastAuthState(isAuth);

            userStore.updateFromCheckResponse(data);

            // Check if the user needs onboarding
            if (isAuth && !data.onboarded && !isRedirecting) {
                // Redirect to onboarding page if not in onboarding or auth paths
                const currentPath = window.location.pathname;
                // Don't redirect if already on onboarding or any auth path
                if (!currentPath.includes('/onboarding') && !currentPath.includes('/auth')) {
                    isRedirecting = true;
                    goto('/onboarding').then(() => {
                        // Reset the flag after navigation completes
                        isRedirecting = false;
                    }).catch(() => {
                        // Also reset the flag if navigation fails
                        isRedirecting = false;
                    });
                }
            }

            return isAuth;
        }

        return false;
    } catch (error) {
        // Network error or other exception - server might be offline
        console.error('Auth check failed (server might be offline):', error);

        // Use the last known authentication state
        return getLastAuthState();
    }
}

/**
 * Checks if the user is authenticated but needs onboarding
 * Returns true if the user needs to complete onboarding
 */
export async function needsOnboarding(fetch: typeof window.fetch): Promise<boolean> {
    // If we're not in a browser, we can't check cookies or localStorage
    if (!browser) return false;

    try {
        const response = await fetch(getApiUrl('auth/check'), {
            credentials: 'include'
        });

        if (response.ok) {
            const data: CheckResponse = await response.json();
            return data.authenticated && !data.onboarded;
        }

        return false;
    } catch (error) {
        console.error('Onboarding check failed:', error);
        return false;
    }
}

/**
 * Stores the last known authentication state in localStorage
 */
function storeLastAuthState(isAuthenticated: boolean): void {
    if (!browser) return;

    try {
        localStorage.setItem(LAST_AUTH_STATE_KEY, JSON.stringify({
            authenticated: isAuthenticated,
            timestamp: Date.now()
        }));
    } catch (e) {
        console.error('Failed to store auth state:', e);
    }
}

/**
 * Retrieves the last known authentication state from localStorage
 * If no state is found or the state is too old, defaults to false (unauthenticated)
 */
function getLastAuthState(): boolean {
    if (!browser) return false;

    try {
        const storedData = localStorage.getItem(LAST_AUTH_STATE_KEY);
        if (!storedData) return false;

        const { authenticated, timestamp } = JSON.parse(storedData);

        // Check if the stored state is not too old (e.g., less than 24 hours or whatever matches your JWT expiry)
        const MAX_AGE = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
        if (Date.now() - timestamp > MAX_AGE) {
            localStorage.removeItem(LAST_AUTH_STATE_KEY);
            return false;
        }

        return authenticated;
    } catch (e) {
        console.error('Failed to retrieve auth state:', e);
        return false;
    }
} 