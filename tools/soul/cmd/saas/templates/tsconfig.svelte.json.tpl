{
    "compilerOptions": {
        "rootDir": "./src/svelte",
        "outDir": "./dist/svelte",
        "baseUrl": "./",
        "paths": {
            "@/*": [
                "src/*"
            ]
        },
        "strict": true,
        "module": "ESNext",
        "moduleResolution": "Node",
        "target": "ES2015", // Update this to ES2015 or later if needed
        "lib": [
            "DOM",
            "ES2015"
        ], // Include the necessary ECMAScript libraries
        "esModuleInterop": true,
        "skipLibCheck": true,
        "forceConsistentCasingInFileNames": true,
        "verbatimModuleSyntax": true, // Required for Svelte
        "types": [
            "svelte"
        ]
    },
    "include": [
        "src/svelte/**/*.ts",
        "src/svelte/**/*.svelte"
    ],
    "exclude": [
        "node_modules",
        "**/*.spec.ts"
    ]
}