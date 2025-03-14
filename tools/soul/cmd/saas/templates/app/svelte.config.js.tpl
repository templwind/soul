import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		adapter: adapter({
			// Set the build output directory
			// This will create a static directory with your built site
			pages: 'build',
			assets: 'build',
			fallback: '200.html', // For SPA mode
			precompress: false,
			strict: false
		}),
		paths: {
			relative: false
		}
	}
};

export default config;
