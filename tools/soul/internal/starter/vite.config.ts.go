package starter

import (
	"path/filepath"

	"github.com/templwind/templwind/tools/soul/templates"
)

type viteServer struct {
	Open bool
	Port int
}

type viteBuild struct {
	OutDir        string
	Sourcemap     bool
	RollupOptions viteRollupOptions
}

type viteRollupOptions struct {
	Input  map[string]string
	Output viteOutput
}

type viteOutput struct {
	EntryFileNames string
	AssetFileNames string
}

type viteConfig struct {
	Server viteServer
	Build  viteBuild
}

func createViteConfig(fullPath, fileName, framework string) error {
	return templates.NewWriter(
		templates.WithOutputFilePath(filepath.Join(fullPath, fileName)),
		templates.WithTemplatePath(filepath.Join(baseTplPath, fileName+".tpl")),
		templates.WithTemplateName(fileName),
		templates.WithData(viteConfig{
			Server: viteServer{
				Open: false,
				Port: 3000,
			},
			Build: viteBuild{
				OutDir:    "assets",
				Sourcemap: true,
				RollupOptions: viteRollupOptions{
					Input: map[string]string{
						"main":   "src/main.ts",
						"styles": "src/styles.scss",
					},
					Output: viteOutput{
						EntryFileNames: "js/[name].js",
						AssetFileNames: "css/[name][extname]",
					},
				},
			},
		}),
	).Write()
}
