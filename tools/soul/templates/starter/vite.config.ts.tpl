import { defineConfig } from {{ quote "vite" }};

export default defineConfig({
    server: {
        open: {{ .Server.Open }},
        port: {{ .Server.Port }}
    },
    build: {
        outDir: {{ quote .Build.OutDir }},
        sourcemap: {{ .Build.Sourcemap }},
        rollupOptions: {
            input: {
                main: {{ quote .Build.RollupOptions.Input.main }},
                styles: {{ quote .Build.RollupOptions.Input.styles }}
            },
            output: {
                entryFileNames: {{ quote .Build.RollupOptions.Output.EntryFileNames }},
                assetFileNames: (asset) => {
                    if (asset.name?.endsWith('.css')) {
                        return {{ quote "css/[name][extname]" }};
                    }
                    return {{ quote "assets/[name][extname]" }};
                }
            }
        }
    }
});
