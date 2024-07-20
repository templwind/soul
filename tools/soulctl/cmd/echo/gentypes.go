package echo

import (
	_ "embed"
	"fmt"
	"io"
	"os"
	"path"
	"strings"

	"github.com/templwind/soul/tools/soulctl/internal/types"
	"github.com/templwind/soul/tools/soulctl/internal/util"
	"github.com/templwind/soul/tools/soulctl/pkg/site/spec"

	"github.com/zeromicro/go-zero/tools/goctl/config"
	gotctlutil "github.com/zeromicro/go-zero/tools/goctl/util"
	"github.com/zeromicro/go-zero/tools/goctl/util/format"
)

const typesFile = "types"

//go:embed templates/types.tpl
var typesTemplate string

// BuildTypes gen types to string
func BuildTypes(types []spec.Type) (string, error) {
	var builder strings.Builder
	first := true
	for _, tp := range types {
		if first {
			first = false
		} else {
			builder.WriteString("\n\n")
		}
		if err := writeType(&builder, tp); err != nil {
			return "", util.WrapErr(err, "Type "+tp.GetName()+" generate error")
		}
	}

	return builder.String(), nil
}

func genTypes(dir string, cfg *config.Config, spec *spec.SiteSpec) error {
	val, err := BuildTypes(spec.Types)
	if err != nil {
		return err
	}

	consts := make(map[string]string, 0)
	for _, s := range spec.Servers {
		for _, srv := range s.Services {
			for _, h := range srv.Handlers {
				for _, m := range h.Methods {
					if m.IsSocket {
						for _, t := range m.SocketNode.Topics {
							constName := "Topic" + util.ToPascal(t.Topic)
							if _, ok := consts[constName]; !ok {
								consts[constName] = t.Topic
							}
						}
					}
				}
			}
		}
	}

	typeFilename, err := format.FileNamingFormat(cfg.NamingFormat, typesFile)
	if err != nil {
		return err
	}

	typeFilename = typeFilename + ".go"
	filename := path.Join(dir, types.TypesDir, typeFilename)
	os.Remove(filename)

	return genFile(fileGenConfig{
		dir:             dir,
		subdir:          types.TypesDir,
		filename:        typeFilename,
		templateName:    "typesTemplate",
		category:        category,
		templateFile:    typesTemplateFile,
		builtinTemplate: typesTemplate,
		data: map[string]any{
			"Types":        val,
			"ContainsTime": false,
			"Consts":       consts,
			"HasConsts":    len(consts) > 0,
		},
	})
}

func writeType(writer io.Writer, tp spec.Type) error {
	fmt.Fprintf(writer, "type %s struct {\n", gotctlutil.Title(tp.GetName()))
	for _, member := range tp.GetFields() {
		if member.Name == member.Type {
			if _, err := fmt.Fprintf(writer, "\t%s\n", strings.Title(member.Type)); err != nil {
				return err
			}

			continue
		}

		if err := util.WriteProperty(writer, member.Name, member.Tag, "", member.Type, 1); err != nil {
			return err
		}
	}
	fmt.Fprintf(writer, "}")
	return nil
}
