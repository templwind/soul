package templates

import (
	"embed"
	"fmt"
	"html/template"
	"io/fs"
	"os"
	"strings"
	"time"

	"github.com/templwind/templwind/tools/soul/internal/util"
)

//go:embed all:*
var templatesFS embed.FS

// Walk through the embedded filesystem and get all *.tpl files under the given rootPath
func GetTplFiles(rootPath string) ([]string, error) {
	var tplFiles []string
	err := fs.WalkDir(templatesFS, rootPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() && strings.HasSuffix(d.Name(), ".tpl") {
			// strip the .tpl extension
			path = strings.TrimSuffix(path, ".tpl")
			tplFiles = append(tplFiles, path)
		}
		return nil
	})
	return tplFiles, err
}

type writeOpts struct {
	OutputFilePath string
	TemplatePath   string
	TemplateName   string
	Data           interface{}
	FuncMap        template.FuncMap
}

type Writer struct {
	opts *writeOpts
}

func NewWriter(opts ...OptFunc) *Writer {
	o := defaultOpts()
	for _, fn := range opts {
		fn(&o)
	}
	return &Writer{
		opts: &o,
	}
}

func (w *Writer) Write(opts ...OptFunc) error {
	outputFile, err := os.Create(w.opts.OutputFilePath)
	if err != nil {
		return fmt.Errorf("failed to create output file: %v", err)
	}
	defer outputFile.Close()

	fmt.Println(os.Getwd())

	// Parse the template
	templateContent, err := templatesFS.ReadFile(w.opts.TemplatePath)
	if err != nil {
		return fmt.Errorf("failed to read template file: %v", err)
	}

	tmpl, err := template.New(w.opts.TemplateName).
		Funcs(w.opts.FuncMap).
		Parse(string(templateContent))
	if err != nil {
		return fmt.Errorf("failed to parse template: %v", err)
	}
	// Execute the template with the data struct
	err = tmpl.Execute(outputFile, w.opts.Data)
	if err != nil {
		return fmt.Errorf("failed to execute template: %v", err)
	}

	fmt.Printf("Successful wrote: %s\n", w.opts.OutputFilePath)

	return nil
}

// OptFunc is a generic function type for properties
type OptFunc func(*writeOpts)

func defaultOpts() writeOpts {
	return writeOpts{
		FuncMap: template.FuncMap{
			"quote": func(s string) template.HTML {
				return template.HTML(fmt.Sprintf("%q", s))
			},
			"ticked": func(s string) template.HTML {
				return template.HTML(fmt.Sprintf("`%s`", s))
			},
			"envvar": func(s string) template.HTML {
				return template.HTML(fmt.Sprintf("{{ %s }}", s))
			},
			"braced": func(s string) template.HTML {
				return template.HTML(fmt.Sprintf("{ %s }", s))
			},
			"safeHTML": func(s string) template.HTML {
				return template.HTML(s)
			},
			"safeJS": func(s string) template.JS {
				return template.JS(s)
			},
			"lower":    strings.ToLower,
			"upper":    strings.ToUpper,
			"camel":    util.ToCamel,
			"kebab":    util.ToKebab,
			"title":    util.ToTitle,
			"snake":    util.ToSnake,
			"pascal":   util.ToPascal,
			"constant": util.ToConstant,
			"trim":     strings.TrimSpace,
			"replace":  strings.ReplaceAll,
			"repeat": func(s string, count int) string { // Repeats the string n times
				return strings.Repeat(s, count)
			},
			"datetime": func(layout, value string) string { // Parses and formats datetime strings
				t, _ := time.Parse(time.RFC3339, value)
				return t.Format(layout)
			},
			"addslashes": func(s string) string { // Escapes quotes and other characters in a string
				return strings.ReplaceAll(strings.ReplaceAll(s, "\\", "\\\\"), "\"", "\\\"")
			},
			"nl2br": func(s string) template.HTML { // Converts newlines to <br> HTML tags
				return template.HTML(strings.ReplaceAll(s, "\n", "<br>"))
			},
		},
	}
}

func WithOutputFilePath(outputFilePath string) func(*writeOpts) {
	return func(opts *writeOpts) {
		opts.OutputFilePath = outputFilePath
	}
}

func WithTemplatePath(templatePath string) func(*writeOpts) {
	return func(opts *writeOpts) {
		opts.TemplatePath = templatePath
	}
}

func WithTemplateName(templateName string) func(*writeOpts) {
	return func(opts *writeOpts) {
		opts.TemplateName = templateName
	}
}

func WithData(data interface{}) func(*writeOpts) {
	return func(opts *writeOpts) {
		opts.Data = data
	}
}

func WithFuncMap(funcMap template.FuncMap) func(*writeOpts) {
	return func(opts *writeOpts) {
		opts.FuncMap = funcMap
	}
}
