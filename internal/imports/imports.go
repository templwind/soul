package imports

import (
	"fmt"
	"strings"
)

type OptFunc func(*Imports)

type Imports struct {
	Imports         []string
	nativeImports   []OptFunc
	projectImports  []OptFunc
	externalImports []OptFunc
	addedList       map[string]struct{}
}

func (i *Imports) String() string {
	return strings.Join(i.Imports, "\n\t")
}

func (i *Imports) GetImports() []string {
	return i.Imports
}

// New creates a new Imports instance
func New(opts ...OptFunc) *Imports {
	imports := &Imports{
		Imports:         make([]string, 0),
		nativeImports:   make([]OptFunc, 0),
		projectImports:  make([]OptFunc, 0),
		externalImports: make([]OptFunc, 0),
		addedList:       make(map[string]struct{}),
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

		if _, exists := i.addedList[path]; !exists {
			i.addedList[path] = struct{}{}
			i.Imports = append(i.Imports, importStr)
		}
	}
}

func WithImports(imports map[string]string) OptFunc {
	return func(i *Imports) {
		for path, alias := range imports {
			WithImport(path, alias)(i)
		}
	}
}

// AddNativeImport adds a native import if it hasn't been added before
func (i *Imports) AddNativeImport(pkg string) {
	if _, exists := i.addedList[pkg]; !exists {
		i.addedList[pkg] = struct{}{}
		i.nativeImports = append(i.nativeImports, WithImport(pkg))
	}
}

// AddProjectImport adds a project import if it hasn't been added before
func (i *Imports) AddProjectImport(pkg string, alias ...string) {
	if _, exists := i.addedList[pkg]; !exists {
		i.addedList[pkg] = struct{}{}
		i.projectImports = append(i.projectImports, WithImport(pkg, alias...))
	}
}

// AddExternalImport adds an external import if it hasn't been added before
func (i *Imports) AddExternalImport(pkg string, alias ...string) {
	if _, exists := i.addedList[pkg]; !exists {
		i.addedList[pkg] = struct{}{}
		i.externalImports = append(i.externalImports, WithImport(pkg, alias...))
	}
}

// Build generates the final import string
func (i *Imports) Build() string {
	var iOptFuncs []OptFunc
	iOptFuncs = append(iOptFuncs, i.nativeImports...)
	if len(i.projectImports) > 0 {
		iOptFuncs = append(iOptFuncs, WithSpacer())
		iOptFuncs = append(iOptFuncs, i.projectImports...)
	}
	if len(i.externalImports) > 0 {
		iOptFuncs = append(iOptFuncs, WithSpacer())
		iOptFuncs = append(iOptFuncs, i.externalImports...)
	}

	finalImports := New(iOptFuncs...)
	return finalImports.String()
}
