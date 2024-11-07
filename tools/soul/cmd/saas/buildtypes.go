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

	filename := path.Join(builder.Dir, path.Join(builder.ServiceName, types.TypesDir), "types.go")
	os.Remove(filename)

	builder.Data["Types"] = val
	builder.Data["ContainsTime"] = false
	builder.Data["Consts"] = consts
	builder.Data["HasConsts"] = len(consts) > 0

	return builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.TypesDir),
		templateFile: "templates/app/internal/types/types.go.tpl",
		data:         builder.Data,
	})
}

func ensureUniqueTypeName(typeName string, existingTypes map[string]bool) string {
	baseName := gotctlutil.Title(typeName)
	uniqueName := baseName
	counter := 1

	// Keep adding a number suffix until we find a unique name
	for existingTypes[uniqueName] {
		uniqueName = fmt.Sprintf("%s%d", baseName, counter)
		counter++
	}

	existingTypes[uniqueName] = true
	return uniqueName
}

// gen gen types to string
func genTypes(builder *SaaSBuilder) (string, error) {
	var strBuilder strings.Builder
	first := true
	existingTypes := make(map[string]bool)

	for _, tp := range builder.Spec.Types {
		if first {
			first = false
		} else {
			strBuilder.WriteString("\n\n")
		}

		// Ensure unique type name before writing
		uniqueTypeName := ensureUniqueTypeName(tp.GetName(), existingTypes)

		if err := writeTypeWithName(&strBuilder, tp, uniqueTypeName); err != nil {
			return "", util.WrapErr(err, "Type "+uniqueTypeName+" generate error")
		}
	}

	return strBuilder.String(), nil
}

func writeTypeWithName(writer io.Writer, tp spec.Type, typeName string) error {
	fmt.Fprintf(writer, "type %s struct {\n", typeName)
	for _, member := range tp.GetFields() {
		if err := util.WriteProperty(writer, member.Name, member.Tag, "", member.Type, 1); err != nil {
			return err
		}
	}
	fmt.Fprintf(writer, "}")
	return nil
}
