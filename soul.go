package soul

import (
	"bytes"
	"context"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/a-h/templ"
	"github.com/labstack/echo/v4"
	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/parser"
	"github.com/yuin/goldmark/renderer/html"
)

// Component interface with generic methods
type Component[T any] interface {
	New(props ...OptFunc[T]) templ.Component
	NewWithOpt(prop *T) templ.Component
	WithProps(props ...OptFunc[T]) *T
}

// OptFunc is a generic function type for props
type OptFunc[T any] func(*T)

// New creates a new templ.Component with the given props
func New[T any](defaultProps func() *T, tpl func(*T) templ.Component, props ...OptFunc[T]) templ.Component {
	prop := WithProps(defaultProps, props...)
	return tpl(prop)
}

// NewWithProps creates a new templ.Component with the given prop
func NewWithProps[T any](tpl func(*T) templ.Component, props *T) templ.Component {
	return tpl(props)
}

// WithProps constructs the props with the given prop functions
func WithProps[T any](defaultProps func() *T, props ...OptFunc[T]) *T {
	defaults := defaultProps()
	for _, propFn := range props {
		propFn(defaults)
	}
	return defaults
}

type BufferedResponseWriter struct {
	originalWriter http.ResponseWriter
	buffer         *bytes.Buffer
	status         int
	wroteHeader    bool
	cookies        []*http.Cookie
}

func (w *BufferedResponseWriter) Header() http.Header {
	return w.originalWriter.Header()
}

func (w *BufferedResponseWriter) Write(b []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(w.status)
	}
	return w.buffer.Write(b)
}

func (w *BufferedResponseWriter) WriteHeader(statusCode int) {
	if !w.wroteHeader {
		w.status = statusCode
		w.wroteHeader = true
	}
}

func (w *BufferedResponseWriter) SetCookie(cookie *http.Cookie) {
	w.cookies = append(w.cookies, cookie)
}

func Render(ctx echo.Context, status int, t templ.Component) error {
	bufferedWriter := &BufferedResponseWriter{
		originalWriter: ctx.Response().Writer,
		buffer:         &bytes.Buffer{},
		status:         status,
	}

	type contextKey string
	// Create a new context with the buffered writer
	const echoKey contextKey = "echo"
	renderCtx := context.WithValue(context.Background(), echoKey, ctx)

	const bufferedWriterKey contextKey = "bufferedWriter"
	renderCtx = context.WithValue(renderCtx, bufferedWriterKey, bufferedWriter)

	// Render to the buffered writer only
	err := t.Render(renderCtx, bufferedWriter)
	if err != nil {
		log.Println(err)
		return ctx.String(http.StatusInternalServerError, "failed to render response template")
	}

	// Set the cookies before writing the response
	for _, cookie := range bufferedWriter.cookies {
		ctx.SetCookie(cookie)
	}

	// Now write the status and body to the original writer
	if !ctx.Response().Committed {
		ctx.Response().WriteHeader(bufferedWriter.status)
	}

	_, err = bufferedWriter.buffer.WriteTo(ctx.Response().Writer)
	if err != nil {
		log.Println(err)
		return ctx.String(http.StatusInternalServerError, "failed to write buffered response")
	}

	return nil
}

// func Render(ctx echo.Context, status int, t templ.Component) error {
// 	if !ctx.Response().Committed {
// 		ctx.Response().WriteHeader(status)
// 	}

// 	err := t.Render(context.Background(), ctx.Response().Writer)
// 	if err != nil {
// 		log.Println(err)
// 		return ctx.String(http.StatusInternalServerError, "failed to render response template")
// 	}

// 	return nil
// }

func ComponentToString(c templ.Component) (string, error) {
	var sb strings.Builder
	err := c.Render(context.Background(), &sb)
	if err != nil {
		return "", err
	}
	return sb.String(), nil
}

func Unsafe(html string) templ.Component {
	return templ.ComponentFunc(func(ctx context.Context, w io.Writer) (err error) {
		_, err = io.WriteString(w, html)
		return
	})
}

func Markdown(markdown string) templ.Component {
	md := goldmark.New(
		goldmark.WithExtensions(
			extension.GFM,           // GitHub Flavored Markdown (tables, strikethrough, etc.)
			extension.Linkify,       // Automatically turns URLs into links
			extension.Strikethrough, // Strikethrough support
		),
		goldmark.WithParserOptions(
			parser.WithAutoHeadingID(), // Automatically generates heading IDs
		),
		goldmark.WithRendererOptions(
			html.WithUnsafe(), // Allows rendering of raw HTML in Markdown
		),
	)

	var buf bytes.Buffer
	if err := md.Convert([]byte(markdown), &buf); err != nil {
		log.Printf("failed to convert markdown to HTML: %v", err)
	}
	return Unsafe(buf.String())
}
