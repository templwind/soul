package util

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path"
	"strings"

	"github.com/templwind/soul/tools/soulctl/internal/types"
	"github.com/templwind/soul/tools/soulctl/pkg/site/spec"

	"github.com/zeromicro/go-zero/core/collection"
	"github.com/zeromicro/go-zero/core/logx"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

// Copy calls io.copy if the source file and destination file exists
func Copy(src, dst string) (int64, error) {
	sourceFileStat, err := os.Stat(src)
	if err != nil {
		return 0, err
	}

	if !sourceFileStat.Mode().IsRegular() {
		return 0, fmt.Errorf("%s is not a regular file", src)
	}

	source, err := os.Open(src)
	if err != nil {
		return 0, err
	}
	defer source.Close()

	destination, err := os.Create(dst)
	if err != nil {
		return 0, err
	}
	defer destination.Close()
	nBytes, err := io.Copy(destination, source)
	return nBytes, err
}

// maybeCreateFile creates file if not exists
func MaybeCreateFile(dir, subdir, file string) (fp *os.File, created bool, err error) {
	logx.Must(pathx.MkdirIfNotExist(path.Join(dir, subdir)))
	fpath := path.Join(dir, subdir, file)
	if pathx.FileExists(fpath) {
		fmt.Printf("%s exists, ignored generation\n", fpath)
		return nil, false, nil
	}

	fp, err = pathx.CreateIfNotExist(fpath)
	created = err == nil
	return
}

// WrapErr wraps an error with message
func WrapErr(err error, message string) error {
	return errors.New(message + ", " + err.Error())
}

func WriteProperty(writer io.Writer, name, tag, comment, tp string, indent int) error {
	WriteIndent(writer, indent)
	var err error
	if len(comment) > 0 {
		comment = strings.TrimPrefix(comment, "//")
		comment = "//" + comment
		_, err = fmt.Fprintf(writer, "%s %s %s %s\n", strings.Title(name), tp, tag, comment)
	} else {
		_, err = fmt.Fprintf(writer, "%s %s %s\n", strings.Title(name), tp, tag)
	}

	return err
}

// WriteIndent writes tab spaces
func WriteIndent(writer io.Writer, indent int) {
	for i := 0; i < indent; i++ {
		fmt.Fprint(writer, "\t")
	}
}

func GetAuths(spec *spec.SiteSpec) []string {
	authNames := collection.NewSet()
	for _, s := range spec.Servers {
		jwt := s.GetAnnotation("jwt")
		if len(jwt) > 0 {
			authNames.Add(jwt)
		}
	}
	return authNames.KeysStr()
}

func GetJwtTrans(spec *spec.SiteSpec) []string {
	jwtTransList := collection.NewSet()
	for _, s := range spec.Servers {
		jt := s.GetAnnotation(types.JwtTransKey)
		if len(jt) > 0 {
			jwtTransList.Add(jt)
		}
	}
	return jwtTransList.KeysStr()
}

func GetMiddleware(spec *spec.SiteSpec) []string {
	result := collection.NewSet()
	for _, s := range spec.Servers {
		middleware := s.GetAnnotation("middleware")
		if len(middleware) > 0 {
			for _, item := range strings.Split(middleware, ",") {
				result.Add(strings.TrimSpace(item))
			}
		}
	}

	return result.KeysStr()
}

// getDoc formats the documentation map into a string
func GetDoc(doc map[string]interface{}) string {
	if len(doc) == 0 {
		return ""
	}
	var resp strings.Builder
	for key, val := range doc {
		resp.WriteString(fmt.Sprintf("// %s: %s\n", key, strings.Trim(val.(string), "\"")))
	}
	return resp.String()
}

func RequestGoTypeName(r spec.Method, pkg ...string) string {
	if r.RequestType == nil {
		return ""
	}

	req := GolangExpr(r.RequestType, pkg...)
	switch r.ResponseType.(type) {
	case *spec.StructType:
		if !strings.HasPrefix(req, "*") {
			return "*" + req
		}
	default:
		if !strings.HasPrefix(req, "*") {
			return "*" + req
		}
	}

	return req
}

func ResponseGoTypeName(r spec.Method, pkg ...string) string {
	if r.ResponseType == nil {
		return ""
	}

	resp := GolangExpr(r.ResponseType, pkg...)
	switch r.ResponseType.(type) {
	case *spec.StructType:
		if !strings.HasPrefix(resp, "*") {
			return "*" + resp
		}
	}

	return resp
}

func TopicRequestGoTypeName(r spec.TopicNode, pkg ...string) string {
	if r.RequestType == nil {
		return ""
	}

	req := GolangExpr(r.RequestType, pkg...)
	switch r.RequestType.(type) {
	case *spec.StructType:
		if !strings.HasPrefix(req, "*") {
			return "*" + req
		}
	}

	return req
}

func TopicResponseGoTypeName(r spec.TopicNode, pkg ...string) string {
	if r.ResponseType == nil {
		return ""
	}

	resp := GolangExpr(r.ResponseType, pkg...)
	switch r.ResponseType.(type) {
	case *spec.StructType:
		if !strings.HasPrefix(resp, "*") {
			return "*" + resp
		}
	}

	return resp
}

func GolangExpr(ty spec.Type, pkg ...string) string {
	switch v := ty.(type) {
	case *spec.PrimitiveType:
		return v.Name
	case *spec.StructType:
		if len(pkg) > 1 {
			panic("package cannot be more than 1")
		}

		if len(pkg) == 0 {
			return v.Name
		}

		return fmt.Sprintf("%s.%s", pkg[0], strings.Title(v.Name))
	case *spec.ArrayType:
		if len(pkg) > 1 {
			panic("package cannot be more than 1")
		}

		if len(pkg) == 0 {
			return v.Name
		}

		return fmt.Sprintf("[]%s", GolangExpr(v.Value, pkg...))
	case *spec.MapType:
		if len(pkg) > 1 {
			panic("package cannot be more than 1")
		}

		if len(pkg) == 0 {
			return v.Name
		}

		return fmt.Sprintf("map[%s]%s", v.Key, GolangExpr(v.Value, pkg...))
	case *spec.PointerType:
		if len(pkg) > 1 {
			panic("package cannot be more than 1")
		}

		if len(pkg) == 0 {
			return v.Name
		}

		return fmt.Sprintf("*%s", GolangExpr(v.Type, pkg...))
	case *spec.InterfaceType:
		return v.Name
	}

	return ""
}
