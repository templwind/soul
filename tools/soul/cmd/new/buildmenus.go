package new

import (
	"fmt"
	"os"
	"path"
	"sort"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
)

func buildMenus(builder *SaaSBuilder) error {

	handlerFile := path.Join(builder.Dir, builder.ServiceName, types.ConfigDir, "menus.go")
	if _, err := os.Stat(handlerFile); err == nil {
		if err := os.Remove(handlerFile); err != nil {
			fmt.Println("error removing file", handlerFile, err)
		}
	}

	// sort the menus by weight
	for _, menu := range builder.Spec.Menus {
		sortMenuEntriesByWeight(menu)
	}

	builder.Data["menus"] = builder.Spec.Menus
	return builder.genFile(fileGenConfig{
		subdir:       builder.ServiceName + "/internal/config",
		templateFile: "templates/app/internal/config/menus.go.tpl",
		data:         builder.Data,
		templateFuncs: template.FuncMap{
			"ConvertAttributesToMap": convertAttributesToMap,
		},
	})
}

func sortMenuEntriesByWeight(entries []spec.MenuEntry) {
	// Sort the current level of entries
	sort.SliceStable(entries, func(i, j int) bool {
		return entries[i].Weight < entries[j].Weight
	})

	// Use a stack to process entries iteratively to avoid deep recursion
	stack := [][]spec.MenuEntry{entries}

	// Iterate over the stack to process each entry's children
	for len(stack) > 0 {
		// Pop the last element from the stack
		currentEntries := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		for i := range currentEntries {
			if len(currentEntries[i].Children) > 0 {
				// Sort the children of the current entry
				sort.SliceStable(currentEntries[i].Children, func(k, l int) bool {
					return currentEntries[i].Children[k].Weight < currentEntries[i].Children[l].Weight
				})
				// Push the children onto the stack to process later
				stack = append(stack, currentEntries[i].Children)
			}
		}
	}
}

// write a function that converts the attributes to a string
func convertAttributesToMap(attributes map[string]string) string {
	// Attributes: map[class:drawer-button for:my-drawer],
	// should be converted to:
	// Attributes: map[class:drawer-button for:my-drawer],
	attrString := "map[string]string{"
	for key, value := range attributes {
		attrString += fmt.Sprintf("\"%s\":`%s`,", key, value)
	}
	attrString += "}"
	return attrString
}
