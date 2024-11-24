// Package httpx provides enhanced HTTP request parsing with support for nested structs,
// multiple array notations, default values, and complete form data handling.
package httpx

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

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

// tagOptions represents parsed tag options including default values
type tagOptions struct {
	name         string   // Field name (e.g., "theme" in query:"theme")
	isOptional   bool     // Whether field is optional
	defaultValue string   // Raw default value string
	defaults     []string // Parsed default values if multiple (pipe separated)
	pathPrefix   string   // For nested fields, e.g., "theme.layout" for "theme.layout.mode"
	isFile       bool     // Whether this is a file field
}

// fieldInfo represents information about a struct field being processed
type fieldInfo struct {
	value     reflect.Value
	field     reflect.StructField
	path      string // Full path to field (e.g., "theme.layout.mode")
	processed bool   // Whether field has been processed (for ambiguity detection)
}

var (
	// Regex patterns for array notation detection
	bracketArrayPattern = regexp.MustCompile(`^(.*?)\[(\d+)\](.*)$`)
	dotArrayPattern     = regexp.MustCompile(`^(.*?\.)(\d+)(.*)$`)
)

// Validator defines the interface for validating parsed data
type Validator interface {
	Validate(c echo.Context, data any) error
}

var validator atomic.Value

// parseTagOptions parses struct field tags and extracts all options
func parseTagOptions(tag string, parentPath string) tagOptions {
	parts := strings.Split(tag, ",")
	opts := tagOptions{
		name:       parts[0],
		pathPrefix: parentPath,
	}

	for _, part := range parts[1:] {
		switch {
		case part == "optional":
			opts.isOptional = true
		case strings.HasPrefix(part, "default="):
			opts.defaultValue = strings.TrimPrefix(part, "default=")
			if strings.Contains(opts.defaultValue, "|") {
				opts.defaults = strings.Split(opts.defaultValue, "|")
			}
		}
	}

	// Build full path for nested fields
	if opts.pathPrefix != "" {
		opts.name = opts.pathPrefix + "." + opts.name
	}

	return opts
}

// Parse handles the complete parsing of an HTTP request
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

// ParseQuery handles URL query parameters with support for nested structs and arrays
func ParseQuery(c echo.Context, v any) error {
	queryParams := c.QueryParams()
	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	processed := make(map[string]bool)
	getValue := func(path string) (string, bool) {
		values := queryParams[path]
		if len(values) > 0 {
			processed[path] = true
			return values[0], true
		}
		return "", false
	}

	return parseStruct(val, "", func(field fieldInfo) error {
		if processed[field.path] {
			return fmt.Errorf("ambiguous field %s specified multiple times", field.path)
		}
		return processField(field, "query", getValue, setFieldValue)
	})
}

// processField handles a single field during parsing
func processField(field fieldInfo, tagKey string, getValue func(path string) (string, bool), setValue func(field reflect.Value, value string) error) error {
	tag := field.field.Tag.Get(tagKey)
	if tag == "" {
		return nil
	}

	opts := parseTagOptions(tag, field.path)

	// Check for ambiguous fields
	if field.processed {
		return fmt.Errorf("ambiguous field %s specified multiple times", opts.name)
	}

	// Get value using provided function
	value, exists := getValue(opts.name)
	if !exists {
		// Try alternate array notations if this is an array field
		if field.value.Kind() == reflect.Slice {
			value, exists = getArrayValue(opts.name, getValue)
		}
	}

	if exists {
		if err := setValue(field.value, value); err != nil {
			return fmt.Errorf("error setting value for %s: %w", opts.name, err)
		}
		field.processed = true
	} else if !opts.isOptional {
		// Try to apply default value
		if opts.defaultValue != "" {
			if err := applyDefaultValue(field.value, opts); err != nil {
				return fmt.Errorf("error applying default value for %s: %w", opts.name, err)
			}
		} else {
			return fmt.Errorf("missing required parameter: %s", opts.name)
		}
	}

	return nil
}

// ParseForm handles both regular form data and multipart form data
func ParseForm(c echo.Context, v any) error {
	isMultipart := strings.HasPrefix(c.Request().Header.Get("Content-Type"), "multipart/form-data")

	if isMultipart {
		if err := c.Request().ParseMultipartForm(maxMemory); err != nil {
			return fmt.Errorf("failed to parse multipart form: %w", err)
		}
	} else {
		if err := c.Request().ParseForm(); err != nil {
			return err
		}
	}

	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	processed := make(map[string]bool)
	getValue := func(path string) (string, bool) {
		var values []string
		if isMultipart {
			values = c.Request().MultipartForm.Value[path]
		} else {
			values = c.Request().Form[path]
		}
		if len(values) > 0 {
			processed[path] = true
			return values[0], true
		}
		return "", false
	}

	// Process form fields
	if err := parseStruct(val, "", func(field fieldInfo) error {
		if processed[field.path] {
			return fmt.Errorf("ambiguous field %s specified multiple times", field.path)
		}
		return processField(field, "form", getValue, setFieldValue)
	}); err != nil {
		return err
	}

	// Handle file uploads if multipart
	if isMultipart {
		if err := parseFiles(c, val, ""); err != nil {
			return err
		}
	}

	return nil
}

// parseFiles handles file uploads in multipart form data
func parseFiles(c echo.Context, val reflect.Value, prefix string) error {
	if val.Kind() == reflect.Ptr {
		if val.IsNil() {
			val.Set(reflect.New(val.Type().Elem()))
		}
		val = val.Elem()
	}

	typ := val.Type()
	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)

		// Build the field path
		fieldPath := fieldType.Name
		if prefix != "" {
			fieldPath = prefix + "." + fieldPath
		}

		// Handle nested structs
		if field.Kind() == reflect.Struct && field.Type() != reflect.TypeOf(time.Time{}) {
			if err := parseFiles(c, field, fieldPath); err != nil {
				return err
			}
			continue
		}

		fileTag := fieldType.Tag.Get("file")
		if fileTag != "" {
			opts := parseTagOptions(fileTag, prefix)
			fileHeader, err := c.FormFile(opts.name)
			if err == nil && fileHeader != nil {
				// Handle standard file metadata fields
				switch fieldType.Name {
				case "Filename":
					field.SetString(fileHeader.Filename)
				case "FileSize":
					field.SetInt(fileHeader.Size)
				case "ContentType":
					field.SetString(fileHeader.Header.Get("Content-Type"))
				}
			} else if !opts.isOptional {
				return fmt.Errorf("missing required file: %s", opts.name)
			}
		}
	}
	return nil
}

// ParseHeaders extracts and parses HTTP headers
func ParseHeaders(c echo.Context, v any) error {
	headers := c.Request().Header
	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	return parseStruct(val, "", func(field fieldInfo) error {
		headerTag := field.field.Tag.Get("header")
		if headerTag == "" {
			return nil
		}

		opts := parseTagOptions(headerTag, field.path)
		headerValue := headers.Get(opts.name)

		if headerValue != "" {
			if err := setFieldValue(field.value, headerValue); err != nil {
				return fmt.Errorf("error setting header parameter %s: %w", opts.name, err)
			}
		} else if !opts.isOptional {
			if opts.defaultValue != "" {
				if err := applyDefaultValue(field.value, opts); err != nil {
					return fmt.Errorf("error applying default value for header %s: %w", opts.name, err)
				}
			} else {
				return fmt.Errorf("missing required header parameter: %s", opts.name)
			}
		}

		return nil
	})
}

// ParsePath handles URL path parameters
func ParsePath(c echo.Context, v any, pattern string) error {
	vars, err := extractPathVars(c, pattern)
	if err != nil {
		return err
	}

	val := reflect.ValueOf(v)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	return parseStruct(val, "", func(field fieldInfo) error {
		pathTag := field.field.Tag.Get("path")
		if pathTag == "" {
			return nil
		}

		opts := parseTagOptions(pathTag, field.path)
		var paramValue string
		if value, ok := vars[opts.name]; ok {
			paramValue = value
		} else {
			paramValue = c.Param(opts.name)
		}

		if paramValue != "" {
			if err := setFieldValue(field.value, paramValue); err != nil {
				return fmt.Errorf("error setting path parameter %s: %w", opts.name, err)
			}
		} else if !opts.isOptional {
			if opts.defaultValue != "" {
				if err := applyDefaultValue(field.value, opts); err != nil {
					return fmt.Errorf("error applying default value for path parameter %s: %w", opts.name, err)
				}
			} else {
				return fmt.Errorf("missing required path parameter: %s", opts.name)
			}
		}

		return nil
	})
}

// getArrayValue handles the three supported array notation styles
func getArrayValue(name string, getValue func(path string) (string, bool)) (string, bool) {
	// Try bracket notation: items[0]
	if matches := bracketArrayPattern.FindStringSubmatch(name); matches != nil {
		base, index, rest := matches[1], matches[2], matches[3]
		return getValue(fmt.Sprintf("%s[%s]%s", base, index, rest))
	}

	// Try dot notation: items.0
	if matches := dotArrayPattern.FindStringSubmatch(name); matches != nil {
		base, index, rest := matches[1], matches[2], matches[3]
		return getValue(fmt.Sprintf("%s%s%s", base, index, rest))
	}

	// Try repeated keys
	return getValue(name)
}

// parseStruct recursively processes struct fields
func parseStruct(val reflect.Value, prefix string, processor func(field fieldInfo) error) error {
	if val.Kind() == reflect.Ptr {
		if val.IsNil() {
			val.Set(reflect.New(val.Type().Elem()))
		}
		val = val.Elem()
	}

	typ := val.Type()
	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)

		// Skip unexported fields
		if !fieldType.IsExported() {
			continue
		}

		// Build the field path
		fieldPath := fieldType.Name
		if prefix != "" {
			fieldPath = prefix + "." + fieldPath
		}

		// Handle nested structs
		if field.Kind() == reflect.Struct {
			if field.Type() != reflect.TypeOf(time.Time{}) {
				if err := parseStruct(field, fieldPath, processor); err != nil {
					return err
				}
				continue
			}
		}

		// Process the field
		if err := processor(fieldInfo{
			value: field,
			field: fieldType,
			path:  fieldPath,
		}); err != nil {
			return err
		}
	}

	return nil
}

// ParseJsonBody handles JSON request body parsing
func ParseJsonBody(c echo.Context, v any) error {
	if withJsonBody(c.Request()) {
		reader := io.LimitReader(c.Request().Body, maxBodyLen)
		return json.NewDecoder(reader).Decode(v)
	}
	return nil
}

// setFieldValue sets a field's value with type conversion
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
	case reflect.Slice:
		return setSliceValue(field, strings.Split(value, ","))
	case reflect.Struct:
		if field.Type() == reflect.TypeOf(time.Time{}) {
			timeValue, err := time.Parse(time.RFC3339, value)
			if err != nil {
				return err
			}
			field.Set(reflect.ValueOf(timeValue))
		} else {
			// Try to parse as JSON for nested structs
			return json.Unmarshal([]byte(value), field.Addr().Interface())
		}
	case reflect.Map:
		mapValue := reflect.MakeMap(field.Type())
		if err := json.Unmarshal([]byte(value), mapValue.Interface()); err != nil {
			return err
		}
		field.Set(mapValue)
	case reflect.Ptr:
		if field.IsNil() {
			field.Set(reflect.New(field.Type().Elem()))
		}
		return setFieldValue(field.Elem(), value)
	default:
		return fmt.Errorf("unsupported field type: %s", field.Kind())
	}
	return nil
}

// setSliceValue sets multiple values to a slice field
func setSliceValue(field reflect.Value, values []string) error {
	slice := reflect.MakeSlice(field.Type(), 0, len(values))
	for _, value := range values {
		newElem := reflect.New(field.Type().Elem()).Elem()
		if err := setFieldValue(newElem, value); err != nil {
			return err
		}
		slice = reflect.Append(slice, newElem)
	}
	field.Set(slice)
	return nil
}

// applyDefaultValue applies default value(s) to a field
func applyDefaultValue(field reflect.Value, opts tagOptions) error {
	if opts.defaultValue == "" {
		return nil
	}

	// Handle slice types with multiple defaults
	if field.Kind() == reflect.Slice && len(opts.defaults) > 0 {
		return setSliceValue(field, opts.defaults)
	}

	// For single values, use the raw default value
	return setFieldValue(field, opts.defaultValue)
}

// extractPathVars extracts path variables from the URL
func extractPathVars(c echo.Context, pattern string) (map[string]string, error) {
	vars := map[string]string{}
	// Extract the named parameters from the path
	for _, param := range c.ParamNames() {
		vars[param] = c.Param(param)
	}

	// If pattern is empty, we don't need to do any further checking
	if pattern == "" {
		return vars, nil
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

// extractParamNames extracts parameter names from a URL path part
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

// ParseHeader parses a single header value that contains key-value pairs
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

// SetValidator configures the validator used for validating parsed data
func SetValidator(val Validator) {
	validator.Store(val)
}

// withJsonBody checks if the request contains JSON data
func withJsonBody(r *http.Request) bool {
	return r.ContentLength > 0 && strings.Contains(r.Header.Get("Content-Type"), "application/json")
}
