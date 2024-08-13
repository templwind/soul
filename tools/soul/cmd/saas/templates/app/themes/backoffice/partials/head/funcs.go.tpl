package head

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/templwind/soul/util"
)

type ProdMetaCache map[string]ProdFile

// SetProdCache reads CSS and JS files, calculates SRI, and populates the ProdMetaCache
func SetProdCache(directory string) (ProdMetaCache, error) {
	cache := make(ProdMetaCache)

	err := filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && filepath.Ext(path) == ".css" || filepath.Ext(path) == ".js" {
			sri, err := util.CalculateSRI(path)
			if err != nil {
				return fmt.Errorf("failed to calculate SRI for %s: %w", path, err)
			}

			// Assuming MinifiedPermalink is the same as Path for this example
			cache[path] = ProdFile{
				MinifiedPermalink: path,
				Integrity:         sri,
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return cache, nil
}
