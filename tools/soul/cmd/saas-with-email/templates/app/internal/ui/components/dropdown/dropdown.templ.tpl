package dropdown

import "fmt"

templ tpl(props *Props) {
	<div x-data={ fmt.Sprintf("{ %sTitle: '%s' }", props.ID, props.Links[0].Title) }>
		<button
			id={ fmt.Sprintf("%sDefaultButton", props.ID) }
			data-dropdown-toggle={ props.ID }
			data-dropdown-offset-distance="4"
			class="inline-flex w-full items-center justify-between rounded-lg bg-blue-700 px-5 py-2.5 text-center text-sm font-medium text-white hover:bg-blue-800 focus:outline-none focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
			type="button"
		>
			<span x-text={ fmt.Sprintf("%sTitle", props.ID) } class="font-semibold"></span>
			<svg class="ms-3 h-2.5 w-2.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
				<path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 4 4 4-4"></path>
			</svg>
		</button>
		<!-- Dropdown menu -->
		<div
			id={ props.ID }
			class="z-10 mx-auto hidden w-full divide-y divide-gray-100 rounded-lg bg-white shadow dark:bg-gray-700"
		>
			<ul class="py-2 text-sm text-gray-700 dark:text-gray-200" aria-labelledby={ fmt.Sprintf("%sDefaultButton", props.ID) }>
				for _, item := range props.Links {
					<li>
						<button
							if item.Link != "" {
								hx-get={ item.Link }
							}
							@click={ fmt.Sprintf(`%s; window.FlowbiteInstances._instances.Dropdown.%s.hide(); %sTitle = '%s'`, item.Click, props.ID, props.ID, item.Title) }
							class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white"
						>{ item.Title }</button>
					</li>
				}
			</ul>
		</div>
	</div>
}
