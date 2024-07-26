import { defineConfig } from "vite";
import { resolve } from "path";

export default defineConfig({
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
        admin: resolve(__dirname, "src/admin.ts"),
        app: resolve(__dirname, "src/app.ts"),
        main: resolve(__dirname, "src/main.ts"),
      },
      output: {
        format: "es",
        entryFileNames: "js/[name].js",
        chunkFileNames: "js/[name].js",
        assetFileNames: (assetInfo) => {
          if (assetInfo.name.endsWith(".css")) {
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
});
