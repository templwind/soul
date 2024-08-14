package saas

import (
	"fmt"
	"os"
	"path"
	"sort"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
)

func buildMenus(builder *SaaSBuilder) error {

	handlerFile := path.Join(builder.Dir, "app", types.ConfigDir, "menus.go")
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
		subdir:       "app/internal/config",
		templateFile: "templates/app/internal/config/menus.go.tpl",
		data:         builder.Data,
	})
}

func sortMenuEntriesByWeight(entries []spec.MenuEntry) {
	sort.SliceStable(entries, func(i, j int) bool {
		return entries[i].Weight < entries[j].Weight
	})
	for i := range entries {
		if len(entries[i].Children) > 0 {
			sortMenuEntriesByWeight(entries[i].Children)
		}
	}
}
