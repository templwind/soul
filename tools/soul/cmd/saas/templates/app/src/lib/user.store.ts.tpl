import { browser } from "$app/environment";
import type { CheckResponse } from "$lib/api/models";
import { get, writable, type Writable } from 'svelte/store';

export interface UserState {
    authenticated: boolean;
    onboarded: boolean;
    username?: string;
    firstName?: string;
    lastName?: string;
    email?: string;
}

const defaultState: UserState = {
    authenticated: false,
    onboarded: false
};

// Create the store with default or persisted state
const createUserStore = () => {
    // Initialize from localStorage if in browser
    const getInitialState = (): UserState => {
        if (!browser) return defaultState;

        try {
            const storedState = localStorage.getItem('userState');
            return storedState ? JSON.parse(storedState) : defaultState;
        } catch (e) {
            console.error('Failed to parse stored user state:', e);
            return defaultState;
        }
    };

    const store = writable<UserState>(getInitialState());

    // Subscribe to changes and update localStorage
    if (browser) {
        store.subscribe(state => {
            try {
                localStorage.setItem('userState', JSON.stringify(state));
            } catch (e) {
                console.error('Failed to store user state:', e);
            }
        });
    }

    return {
        subscribe: store.subscribe,
        set: store.set,
        update: store.update,

        // Method to update store from CheckResponse
        updateFromCheckResponse: (response: CheckResponse) => {
            store.set({
                authenticated: response.authenticated,
                onboarded: response.onboarded,
                username: response.username,
                firstName: response.firstName,
                lastName: response.lastName,
                email: response.email
            });
        },

        // Method to clear user data (logout)
        logout: () => {
            store.set(defaultState);
            if (browser) {
                try {
                    localStorage.removeItem('userState');
                } catch (e) {
                    console.error('Failed to remove user state from storage:', e);
                }
            }
        },

        // Helper to check if user is authenticated
        isAuthenticated: () => get(store).authenticated,

        // Helper to check if user is onboarded
        isOnboarded: () => get(store).onboarded,

        // Helper to get full name
        getFullName: () => {
            const state = get(store);
            if (state.firstName && state.lastName) {
                return `${state.firstName} ${state.lastName}`;
            } else if (state.firstName) {
                return state.firstName;
            } else if (state.username) {
                return state.username;
            }
            return '';
        },

        getFirstName: () => {
            const state = get(store);
            return state.firstName;
        },

        getLastName: () => {
            const state = get(store);
            return state.lastName;
        },

        getEmail: () => {
            const state = get(store);
            return state.email;
        }
    };
};

// Export a singleton instance of the store
export const userStore = createUserStore();
