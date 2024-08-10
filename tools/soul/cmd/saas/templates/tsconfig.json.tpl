{
  "extends": "@tsconfig/svelte/tsconfig.json",
  "compilerOptions": {
    "target": "ESNext", // Targets latest ECMAScript standard
    "useDefineForClassFields": true,
    "module": "ESNext",
    "resolveJsonModule": true,
    "allowJs": true,
    "checkJs": true,
    "isolatedModules": true,
    "moduleDetection": "force"
  },
  "include": [
    "src/svelte/**/*.ts",
    "src/svelte/**/*.js",
    "src/svelte/**/*.svelte"
  ],
  "references": [
    {
      "path": "./tsconfig.node.json"
    }
  ]
}