package modules

import (
	"{{ .ModuleName }}/modules/app"
	"{{ .ModuleName }}/modules/www"
)

// Module registry for all modules
// This	is where you register all the modules used in your application
var registry = map[string]Module{
	"app": app.Module(),
	"www": www.Module(),
}
