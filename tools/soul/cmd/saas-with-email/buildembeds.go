package saas

import (
	_ "embed"
	"fmt"
	"os"
	"path"
)

func buildEmbeds(builder *SaaSBuilder) error {

	embedFile := path.Join(builder.Dir, builder.ServiceName, "embeds.go")
	// fmt.Println("embedFile", embedFile)
	if _, err := os.Stat(embedFile); err == nil {
		if err := os.Remove(embedFile); err != nil {
			fmt.Println("error removing file", embedFile, err)
		}
	}

	builder.Data["EmbeddedFS"] = builder.EmbeddedFS
	// fmt.Println("builder.EmbeddedFS", builder.Data["EmbeddedFS"])

	return builder.genFile(fileGenConfig{
		subdir:       builder.ServiceName + "/",
		templateFile: "templates/app/embeds.go.tpl",
		data:         builder.Data,
	})
}
