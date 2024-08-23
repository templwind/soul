package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"sync/atomic"

	"github.com/labstack/echo/v4"
)

const (
	formKey           = "form"
	pathKey           = "path"
	maxMemory         = 32 << 20 // 32MB
	maxBodyLen        = 8 << 20  // 8MB
	separator         = ";"
	tokensInAttribute = 2
)

// Validator defines the interface for validating the request.
type Validator interface {
	// Validate validates the request and parsed data.
	Validate(c echo.Context, data any) error
}

var validator atomic.Value

// Parse parses the request.
func Parse(c echo.Context, v any, pattern string) error {
	// Check if both JSON and form data are present
	isJSON := withJsonBody(c.Request())
	isForm := c.Request().PostForm != nil && len(c.Request().PostForm) > 0

	if isJSON && isForm {
		return errors.New("cannot mix form and json data")
	}

	if err := ParsePath(c, v, pattern); err != nil {
		return err
	}

	if err := ParseQuery(c, v); err != nil {
		return err
	}

	if err := ParseForm(c, v); err != nil {
		return err
	}

	if err := ParseHeaders(c, v); err != nil {
		return err
	}

	if err := ParseJsonBody(c, v); err != nil {
		return err
	}

	if err := ValidateStruct(v); err != nil {
		return err
	}

	if valid, ok := v.(Validator); ok {
		return valid.Validate(c, v)
	} else if val := validator.Load(); val != nil {
		return val.(Validator).Validate(c, v)
	}

	return nil
}

// ParseHeaders parses the headers request.
func ParseHeaders(c echo.Context, v any) error {
	headers := c.Request().Header
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		headerTag := fieldType.Tag.Get("header")

		if headerTag != "" {
			headerValue := headers.Get(headerTag)
			if headerValue != "" {
				field.SetString(headerValue)
			}
		}
	}

	return nil
}

// ParseForm parses the form request.
func ParseForm(c echo.Context, v any) error {
	if err := c.Request().ParseForm(); err != nil {
		return err
	}

	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		formTag := fieldType.Tag.Get("form")

		if formTag != "" {
			formValue := c.FormValue(formTag)
			if formValue != "" {
				if field.Kind() == reflect.String {
					field.SetString(formValue)
				} else {
					return fmt.Errorf("unsupported field type: %s", field.Kind().String())
				}
			}
		}
	}

	return nil
}

// ParseHeader parses the request header and returns a map.
func ParseHeader(headerValue string) map[string]string {
	ret := make(map[string]string)
	fields := strings.Split(headerValue, separator)

	for _, field := range fields {
		field = strings.TrimSpace(field)
		if len(field) == 0 {
			continue
		}

		kv := strings.SplitN(field, "=", tokensInAttribute)
		if len(kv) != tokensInAttribute {
			continue
		}

		ret[kv[0]] = kv[1]
	}

	return ret
}

// ParseJsonBody parses the post request which contains json in body.
func ParseJsonBody(c echo.Context, v any) error {
	if withJsonBody(c.Request()) {
		reader := io.LimitReader(c.Request().Body, maxBodyLen)
		return json.NewDecoder(reader).Decode(v)
	}

	return nil
}

func ParsePath(c echo.Context, v any, pattern string) error {
	vars, err := extractPathVars(c, pattern)
	if err != nil {
		return err
	}

	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		pathTag := fieldType.Tag.Get("path")

		if pathTag != "" {
			if paramValue, ok := vars[pathTag]; ok {
				field.SetString(paramValue)
			}
		}
	}

	return nil
}

func extractPathVars(c echo.Context, pattern string) (map[string]string, error) {
	vars := map[string]string{}
	// Extract the named parameters from the path
	for _, param := range c.ParamNames() {
		vars[param] = c.Param(param)
	}
	// Check if the actual path matches the expected pattern
	actualPath := c.Request().URL.Path
	patternParts := strings.Split(strings.Trim(pattern, "/"), "/")
	actualParts := strings.Split(strings.Trim(actualPath, "/"), "/")
	// Find where the pattern starts in the actual path
	offset := len(actualParts) - len(patternParts)
	if offset < 0 {
		return nil, fmt.Errorf("path does not match pattern: expected %s, got %s", pattern, actualPath)
	}
	for i, part := range patternParts {
		actualIndex := i + offset
		if strings.HasPrefix(part, ":") {
			// This is a parameter, already handled by Echo
			continue
		} else if strings.Contains(part, ":") {
			// Handle embedded parameters in the pattern
			paramNames := extractParamNames(part)
			remainingPart := actualParts[actualIndex]
			for _, paramName := range paramNames {
				prefix := part[:strings.Index(part, ":"+paramName)]
				if !strings.HasPrefix(remainingPart, prefix) {
					return nil, fmt.Errorf("path does not match pattern: expected %s, got %s", pattern, actualPath)
				}
				remainingPart = strings.TrimPrefix(remainingPart, prefix)
				endIndex := strings.Index(part[strings.Index(part, ":"+paramName)+len(paramName)+1:], ":")
				if endIndex == -1 {
					vars[paramName] = remainingPart
					break
				}
				nextPrefix := part[strings.Index(part, ":"+paramName)+len(paramName)+1 : strings.Index(part, ":"+paramName)+len(paramName)+1+endIndex]
				paramValue := remainingPart[:strings.Index(remainingPart, nextPrefix)]
				vars[paramName] = paramValue
				remainingPart = remainingPart[len(paramValue):]
				part = part[strings.Index(part, ":"+paramName)+len(paramName)+1:]
			}
		} else if part != actualParts[actualIndex] {
			return nil, fmt.Errorf("path does not match pattern: expected %s, got %s", pattern, actualPath)
		}
	}
	return vars, nil
}

func extractParamNames(part string) []string {
	var paramNames []string
	for {
		colonIndex := strings.Index(part, ":")
		if colonIndex == -1 {
			break
		}
		part = part[colonIndex+1:]
		endIndex := strings.IndexAny(part, ":-/")
		if endIndex == -1 {
			paramNames = append(paramNames, part)
			break
		}
		paramNames = append(paramNames, part[:endIndex])
		part = part[endIndex:]
	}
	return paramNames
}

// func ParsePath(c echo.Context, v any, pattern string) error {
// 	path := c.Request().URL.Path
// 	val := reflect.ValueOf(v).Elem()
// 	typ := val.Type()

// 	parts := strings.Split(path, "/")
// 	patternParts := strings.Split(pattern, "/")

// 	// Check if the number of parts matches
// 	if len(parts) != len(patternParts) {
// 		return errors.New("path does not match pattern")
// 	}

// 	vars := map[string]string{}

// // extract variables from the Params in c echo.Context
// for _, param := range c.ParamNames() {
// 	vars[param] = c.Param(param)
// }

// 	for i, part := range patternParts {
// 		if strings.HasPrefix(part, ":") {
// 			varName := part[1:]
// 			vars[varName] = parts[i]
// 		} else if part != parts[i] {
// 			return errors.New("path does not match pattern")
// 		}
// 	}

// 	for i := 0; i < val.NumField(); i++ {
// 		field := val.Field(i)
// 		fieldType := typ.Field(i)
// 		pathTag := fieldType.Tag.Get("path")

// 		if pathTag != "" {
// 			if pathValue, ok := vars[pathTag]; ok {
// 				field.SetString(pathValue)
// 			} else {
// 				return fmt.Errorf("path variable %s not found", pathTag)
// 			}
// 		}
// 	}

// 	return nil
// }

func ParseQuery(c echo.Context, v any) error {
	queryParams := c.QueryParams()
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		queryTag := fieldType.Tag.Get("query")

		if queryTag != "" {
			queryValue := queryParams.Get(queryTag)
			if queryValue != "" {
				if err := setFieldValue(field, queryValue); err != nil {
					return fmt.Errorf("error setting query parameter %s: %w", queryTag, err)
				}
			}
		}
	}

	return nil
}

// setFieldValue sets the value of a field based on its type.
func setFieldValue(field reflect.Value, value string) error {
	switch field.Kind() {
	case reflect.String:
		field.SetString(value)
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		intValue, err := strconv.ParseInt(value, 10, 64)
		if err != nil {
			return err
		}
		field.SetInt(intValue)
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		uintValue, err := strconv.ParseUint(value, 10, 64)
		if err != nil {
			return err
		}
		field.SetUint(uintValue)
	case reflect.Float32, reflect.Float64:
		floatValue, err := strconv.ParseFloat(value, 64)
		if err != nil {
			return err
		}
		field.SetFloat(floatValue)
	case reflect.Bool:
		boolValue, err := strconv.ParseBool(value)
		if err != nil {
			return err
		}
		field.SetBool(boolValue)
	default:
		return fmt.Errorf("unsupported field type: %s", field.Kind().String())
	}
	return nil
}

// SetValidator sets the validator.
// The validator is used to validate the request, only called in Parse,
// not in ParseHeaders, ParseForm, ParseHeader, ParseJsonBody, ParsePath.
func SetValidator(val Validator) {
	validator.Store(val)
}

func withJsonBody(r *http.Request) bool {
	return r.ContentLength > 0 && strings.Contains(r.Header.Get("Content-Type"), "application/json")
}
