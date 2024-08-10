package saas

import (
	_ "embed"
	"fmt"
	"io"
	"os"
	"path"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"

	gotctlutil "github.com/zeromicro/go-zero/tools/goctl/util"
)

func buildTypes(builder *SaaSBuilder) error {
	val, err := genTypes(builder)
	if err != nil {
		return err
	}

	consts := make(map[string]string, 0)
	for _, s := range builder.Spec.Servers {
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

	filename := path.Join(builder.Dir, types.TypesDir, "types.go")
	os.Remove(filename)

	builder.Data["Types"] = val
	builder.Data["ContainsTime"] = false
	builder.Data["Consts"] = consts
	builder.Data["HasConsts"] = len(consts) > 0

	return builder.genFile(fileGenConfig{
		subdir:       types.TypesDir,
		templateFile: "templates/internal/types/types.go.tpl",
		data:         builder.Data,
	})
}

// gen gen types to string
func genTypes(builder *SaaSBuilder) (string, error) {
	var strBuilder strings.Builder
	first := true
	for _, tp := range builder.Spec.Types {
		if first {
			first = false
		} else {
			strBuilder.WriteString("\n\n")
		}
		if err := writeType(&strBuilder, tp); err != nil {
			return "", util.WrapErr(err, "Type "+tp.GetName()+" generate error")
		}
	}

	return strBuilder.String(), nil
}

func writeType(writer io.Writer, tp spec.Type) error {
	fmt.Fprintf(writer, "type %s struct {\n", gotctlutil.Title(tp.GetName()))
	for _, member := range tp.GetFields() {
		// if member.Name == member.Type {
		// 	if _, err := fmt.Fprintf(writer, "\t%s\n", strings.Title(member.Type)); err != nil {
		// 		return err
		// 	}

		// 	continue
		// }

		if err := util.WriteProperty(writer, member.Name, member.Tag, "", member.Type, 1); err != nil {
			return err
		}
	}
	fmt.Fprintf(writer, "}")
	return nil
}
