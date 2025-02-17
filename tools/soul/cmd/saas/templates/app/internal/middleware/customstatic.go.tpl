package middleware

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/labstack/echo/v4"
)

func CustomStaticMiddleware(root string) echo.MiddlewareFunc {
	absRoot, _ := filepath.Abs(root)

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			path := c.Request().URL.Path
			cleanPath := strings.TrimPrefix(path, "/")

			// 1. Try $uri/index.html first (but keep the clean URL)
			indexPath := filepath.Join(absRoot, cleanPath, "index.html")
			if info, err := os.Stat(indexPath); err == nil && !info.IsDir() {
				return c.File(indexPath)
			}

			// 2. Try $uri.html
			htmlPath := filepath.Join(absRoot, cleanPath+".html")
			if info, err := os.Stat(htmlPath); err == nil && !info.IsDir() {
				return c.File(htmlPath)
			}

			// 3. Try $uri (exact match)
			exactPath := filepath.Join(absRoot, cleanPath)
			if info, err := os.Stat(exactPath); err == nil && !info.IsDir() {
				return c.File(exactPath)
			}

			// 4. Try SvelteKit's 200.html fallback
			if _, err := os.Stat(filepath.Join(absRoot, "200.html")); err == nil {
				return c.File(filepath.Join(absRoot, "200.html"))
			}

			// 5. SPA fallback: Serve root index.html
			if _, err := os.Stat(filepath.Join(absRoot, "index.html")); err == nil {
				return c.File(filepath.Join(absRoot, "index.html"))
			}

			// 6. If nothing matches, continue to next handler
			return next(c)
		}
	}
}
