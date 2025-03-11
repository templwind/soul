package tabs

import "fmt"

templ tpl(props *Props) {
	// <header class="border-b border-base-content/10">
	if props.MenuEntries != nil {
		<div class="flex flex-row justify-start w-full mb-4 border-b" role="tablist">
			for _, entry := range props.MenuEntries {
				<a
					if entry.URL != props.Request.RequestURI {
						href={ templ.SafeURL(entry.URL) }
					}
					class={ "tab", templ.KV("border-b-2", props.Request.RequestURI == entry.URL), templ.KV("border-b-2 border-transparent", props.Request.RequestURI != entry.URL) }
					role="tab"
					aria-selected={ fmt.Sprintf("%t", props.Request.RequestURI == entry.URL) }
					aria-controls="tab-content"
				>
					{ entry.Title }
				</a>
			}
		</div>
		// </header>
	}
}
