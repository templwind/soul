package apperror

import (
	"github.com/templwind/soul/util"
	"strings"
)

templ New(errors ...string) {
	<app-error>
		<div class="mb-4 flex rounded-lg bg-red-50 p-4 text-sm text-red-800 dark:bg-slate-800 dark:text-red-400" role="alert">
			<svg class="me-3 mt-[2px] inline h-4 w-4 flex-shrink-0" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
				<path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z"></path>
			</svg>
			<span class="sr-only">Error</span>
			<div>
				<span class="font-medium">There was an error:</span>
				<ul class="mt-1.5 list-inside list-disc">
					for _, err := range errors {
						for _, item := range strings.Split(err, ";") {
							<li>{ util.CutStringFromMatch(item, ":") }</li>
						}
					}
				</ul>
			</div>
		</div>
	</app-error>
}
