import { defineConfig } from "vite";

export default defineConfig({
  server: {
    open: false,
    port: {{.port}},
  },
  build: {
    outDir: "assets/{{.exportName}}",
    sourcemap: true,
    rollupOptions: {
      input: {
        {{.exportName}}: "src/{{.exportName}}.ts",
        styles: "src/styles.scss",
      },
      output: {
        entryFileNames: "js/[name].js",
        assetFileNames: (asset) => {
          if (asset.name?.endsWith(".css")) {
            return "css/[name][extname]";
          }
          return "assets/[name][extname]";
        },
      },
    },
  },
});
