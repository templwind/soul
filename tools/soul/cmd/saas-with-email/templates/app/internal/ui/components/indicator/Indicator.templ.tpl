package indicator

import "fmt"

templ tpl(props *Props) {
	<div
		id={ props.ID }
		class={ "flex flex-col items-center gap-2", templ.KV(props.Class, props.Class != "") }
	>
		<progress
			class="progress progress-info"
			value={ fmt.Sprintf("%d", (props.CurrentStep*100)/props.TotalSteps) }
			max="100"
		></progress>
		<span class="text-sm">Step { fmt.Sprintf("%d", props.CurrentStep) } of { fmt.Sprintf("%d", props.TotalSteps) }</span>
	</div>
}
