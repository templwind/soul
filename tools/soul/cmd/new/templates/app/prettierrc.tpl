{
	"useTabs": true,
	"singleQuote": true,
	"trailingComma": "none",
	"printWidth": 100,
	"plugins": [
		"prettier-plugin-svelte"
	],
	"overrides": [
		{
			"files": "*.svelte",
			"options": {
				"parser": "svelte"
			}
		}
	],
	"svelteSortOrder": "options-scripts-markup-styles",
	"svelteStrictMode": true,
	"svelteBracketNewLine": true,
	"svelteAllowShorthand": true,
	"svelteIndentScriptAndStyle": true,
	"svelteIndentBlockAndTag": true
}