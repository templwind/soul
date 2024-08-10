import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import { sveltePreprocess } from "svelte-preprocess";

export default defineConfig({
  plugins: [
    svelte({
      include: ["src/svelte/**/*.svelte"],
      preprocess: sveltePreprocess({
        typescript: true,
      }),
    }),
  ],
  server: {
    open: false,
    port: 3000,
  },
  build: {
    outDir: "assets",
    sourcemap: true,
    cssCodeSplit: true,
    rollupOptions: {
      input: {
        admin: "src/admin.ts",
        app: "src/app.ts",
        main: "src/main.ts",
      },
      output: {
        format: "es",
        entryFileNames: "js/[name].js",
        chunkFileNames: "js/[name].js",
        assetFileNames: (assetInfo) => {
          if (assetInfo?.name?.endsWith(".css")) {
            return `css/${assetInfo.name}`;
          }
          return "assets/[name][extname]";
        },
      },
    },
  },
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: ``,
        includePaths: ["./src/styles"],
      },
    },
  },
  esbuild: {
    target: "es2019", // Ensure ES2019 target for `flat` method and other modern JS features
    jsxFactory: "h",
    jsxFragment: "Fragment",
  },
});
