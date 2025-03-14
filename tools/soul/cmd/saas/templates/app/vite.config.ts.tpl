import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	server: {
		port: 5173,
		strictPort: false,
		proxy: {
			'/api/ws': {  // WebSocket specific endpoint
				target: 'ws://localhost:8888',
				ws: true,
				configure: (proxy, _options) => {
					proxy.on('error', (err, _req, _res) => {
						console.log('WebSocket proxy error:', err);
					});
				}
			},
			'/api': {     // All other API requests
				target: 'http://localhost:8888',
				changeOrigin: true,
				secure: false,
				rewrite: (path) => path.replace(/^\/api/, ''),
				timeout: 5000,
				configure: (proxy, _options) => {
					proxy.on('error', (err, _req, _res) => {
						console.log('HTTP proxy error:', err);
					});
					proxy.on('proxyReq', (proxyReq, req, _res) => {
						console.log('Sending Request to the Target:', req.method, req.url);
					});
					proxy.on('proxyRes', (proxyRes, req, _res) => {
						console.log('Received Response from the Target:', proxyRes.statusCode, req.url);
					});
				}
			}
		}
	}
});
