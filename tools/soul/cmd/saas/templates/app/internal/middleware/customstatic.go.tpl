package middleware

import (
	"embed"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	gomime "github.com/cubewise-code/go-mime"
	"github.com/labstack/echo/v4"
)

// CustomStaticMiddleware serves static files from either the local filesystem or an embedded FS.
// root is the local filesystem root (used in development).
// embeddedFS is the embedded filesystem (used in production if provided).
// isProduction determines whether to use embeddedFS or the local filesystem.
func CustomStaticMiddleware(root string, embeddedFS *embed.FS, isProduction bool) echo.MiddlewareFunc {
	absRoot, _ := filepath.Abs(root)

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			path := c.Request().URL.Path
			cleanPath := filepath.Join("build", strings.TrimPrefix(path, "/"))

			if isProduction && embeddedFS != nil {
				// Production: Use embedded filesystem
				return serveFromEmbeddedFS(c, embeddedFS, absRoot, cleanPath, next)
			}

			// Development: Use local filesystem
			return serveFromLocalFS(c, absRoot, cleanPath, next)
		}
	}
}

// serveFromLocalFS handles serving files from the local filesystem (development mode).
func serveFromLocalFS(c echo.Context, absRoot, cleanPath string, next echo.HandlerFunc) error {
	// 1. Try $uri/index.html first
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

// serveFromEmbeddedFS handles serving files from an embedded FS (production mode).
func serveFromEmbeddedFS(c echo.Context, embeddedFS *embed.FS, absRoot, cleanPath string, next echo.HandlerFunc) error {
	// get all the details of embeddedFS
	// Normalize paths for embed.FS (use forward slashes)
	embeddedPath := strings.TrimPrefix(cleanPath, "/")
	// 1. Try $uri/index.html first
	indexPath := filepath.ToSlash(filepath.Join(embeddedPath, "index.html"))
	if f, err := embeddedFS.Open(indexPath); err == nil {
		defer f.Close()
		return serveEmbeddedFile(c, embeddedFS, indexPath)
	}

	// 2. Try $uri.html
	htmlPath := filepath.ToSlash(filepath.Join(embeddedPath + ".html"))
	if f, err := embeddedFS.Open(htmlPath); err == nil {
		defer f.Close()
		return serveEmbeddedFile(c, embeddedFS, htmlPath)
	}

	// 3. Try $uri (exact match)
	if f, err := embeddedFS.Open(filepath.Join(embeddedPath)); err == nil {
		defer f.Close()
		return serveEmbeddedFile(c, embeddedFS, filepath.Join(embeddedPath))
	}

	// 4. Try SvelteKit's 200.html fallback
	if f, err := embeddedFS.Open(filepath.Join(absRoot, "200.html")); err == nil {
		defer f.Close()
		return serveEmbeddedFile(c, embeddedFS, filepath.Join(absRoot, "200.html"))
	}

	// 5. SPA fallback: Serve root index.html
	if f, err := embeddedFS.Open(filepath.Join(absRoot, "index.html")); err == nil {
		defer f.Close()
		return serveEmbeddedFile(c, embeddedFS, filepath.Join(absRoot, "index.html"))
	}

	// 6. If nothing matches, continue to next handler
	return next(c)
}

// serveEmbeddedFile serves a file from the embedded FS.
func serveEmbeddedFile(c echo.Context, embeddedFS *embed.FS, path string) error {
	f, err := embeddedFS.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	stat, err := f.Stat()
	if err != nil {
		return err
	}

	contentType := gomime.TypeByExtension(filepath.Ext(path))
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	c.Response().Header().Set("Content-Length", fmt.Sprintf("%d", stat.Size()))
	return c.Stream(http.StatusOK, contentType, f)
}
