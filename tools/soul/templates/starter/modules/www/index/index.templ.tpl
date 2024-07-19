package index

import (
	"{{ .ModuleName }}/internal/ui/layouts/sitelayout"
)

templ index(props *Props) {
	@sitelayout.New(
		sitelayout.WithEcho(props.Echo),
		sitelayout.WithConfig(props.Config),
		) {
		<h1>Welcome to Templwind</h1>
	}
}

