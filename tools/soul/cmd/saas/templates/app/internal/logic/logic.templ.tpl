package {{.pkgName}}

{{ if .hasProps }}
templ {{.templName}}View(props *{{.templName}}Props) {
	<div>
		<h1>{{.pageTitle}}</h1>
	</div>
}
{{ else }}
templ {{.templName}}View() {
	<div>
		<h1>{{.pageTitle}}</h1>
	</div>
}
{{ end }}

