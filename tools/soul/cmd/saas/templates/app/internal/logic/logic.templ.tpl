package {{.pkgName}}

{{ if .hasProps }}
import "goshare/internal/ui/components/page"

templ {{.templName}}View(props *Props) {
	@page.New(
		page.WithTitle(props.PageTitle),
	) {
		<div>
			page content
		</div>
	}
}
{{ else }}
templ {{.templName}}View() {
	<div>
		<h1>{{.pageTitle}}</h1>
	</div>
}
{{ end }}

