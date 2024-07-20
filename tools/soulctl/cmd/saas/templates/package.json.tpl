{
  "name": "{{.serviceName}}",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "build": "concurrently \"tsc && vite build --config vite.config.main.js\" \"tsc && vite build --config vite.config.app.js\" \"tsc && vite build --config vite.config.admin.js\"",
    "build:watch": "concurrently \"tsc && vite build --config vite.config.main.js --watch\" \"tsc && vite build --config vite.config.app.js --watch\" \"tsc && vite build --config vite.config.admin.js --watch\"",
    "dev": "vite",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@tailwindcss/forms": "^0.5.7",
    "@tailwindcss/typography": "^0.5.13",
    "@types/alpinejs": "^3.13.10",
    "autoprefixer": "^10.4.19",
    "concurrently": "^8.2.2",
    "daisyui": "^4.12.10",
    "htmx.org": "^2.0.0",
    "postcss": "^8.4.38",
    "sass": "^1.77.4",
    "tailwindcss": "^3.4.4",
    "typescript": "^5.2.2",
    "vite": "^5.2.0"
  },
  "dependencies": {
    "alpinejs": "^3.14.1"
  }
}