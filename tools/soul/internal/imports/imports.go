package imports

import (
	"fmt"
	"strings"
)

type OptFunc func(*Imports)

type Imports struct {
	Imports []string
}

func (i *Imports) String() string {
	return strings.Join(i.Imports, "\n\t")
}

// New creates a new Imports instance with the provided options
// imports := New(
//
//	    WithImport("fmt"),
//	    WithImport("context", "ctx"),
//	    WithImports(map[string]string{
//		    "net/http":              "",
//		    "io/ioutil":             "",
//		    "math/rand":             "rand",
//		    "github.com/pkg/errors": "errors",
//	    }),
//
// )
func New(opts ...OptFunc) *Imports {
	imports := &Imports{
		Imports: make([]string, 0),
	}
	for _, optFn := range opts {
		optFn(imports)
	}
	return imports
}

func WithSpacer() OptFunc {
	return func(i *Imports) {
		i.Imports = append(i.Imports, "")
	}
}

func WithImport(path string, alias ...string) OptFunc {
	return func(i *Imports) {
		var importStr string

		if len(alias) > 0 && alias[0] != "" {
			importStr = fmt.Sprintf("%s \"%s\"", alias[0], path)
		} else {
			importStr = fmt.Sprintf("\"%s\"", path)
		}

		i.Imports = append(i.Imports, importStr)
	}
}

func WithImports(imports map[string]string) OptFunc {
	return func(i *Imports) {
		for path, alias := range imports {
			WithImport(path, alias)(i)
		}
	}
}
