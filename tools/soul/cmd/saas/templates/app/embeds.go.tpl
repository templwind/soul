package main

import "embed"

{{ range .EmbeddedFS }}
//go:embed all:{{.Path}}/*
var {{.Name}} embed.FS
{{ end }}

// embeddedFS is a map of all the embedded file systems
var embeddedFS = make(map[string]*embed.FS, {{ len .EmbeddedFS }})

func init() {
	{{- range .EmbeddedFS}}
	embeddedFS["{{.Name}}"] = &{{.Name}}
	{{- end}}
}
