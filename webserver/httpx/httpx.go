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
	maxMemory         = 32 << 20 // 32MB
	maxBodyLen        = 8 << 20  // 8MB
	separator         = ";"
	tokensInAttribute = 2
)

// Validator defines the interface for validating the request.
type Validator interface {
	Validate(c echo.Context, data any) error
}

var validator atomic.Value

// Parse parses the request.
func Parse(c echo.Context, v any, pattern string) error {
	// Check if we have both JSON and form data
	contentType := c.Request().Header.Get(echo.HeaderContentType)
	if strings.Contains(contentType, echo.MIMEApplicationJSON) && len(c.Request().PostForm) > 0 {
		return errors.New("cannot mix form and json data")
	}

	parsers := []func(c echo.Context, v any) error{
		func(c echo.Context, v any) error { return ParsePath(c, v, pattern) },
		ParseQuery,
		ParseForm,
		ParseHeaders,
		ParseJsonBody,
		ValidateStruct,
	}

	for _, parse := range parsers {
		if err := parse(c, v); err != nil {
			return err
		}
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
	return parseTags(c.Request().Header.Get, "header", v)
}

// ParseForm parses the form request.
func ParseForm(c echo.Context, v any) error {
	if err := c.Request().ParseForm(); err != nil {
		return err
	}
	return parseTags(c.FormValue, "form", v)
}

// ParseQuery parses the query parameters.
func ParseQuery(c echo.Context, v any) error {
	return parseTags(c.QueryParam, "query", v)
}

// ParsePath parses the symbols residing in the URL path.
func ParsePath(c echo.Context, v any, pattern string) error {
	pathVars, err := extractPathVars(c, pattern)
	if err != nil {
		return err
	}
	return setFieldValues(pathVars, "path", v)
}

// ParseJsonBody parses the post request which contains json in the body.
func ParseJsonBody(c echo.Context, v any) error {
	if withJsonBody(c.Request()) {
		reader := io.LimitReader(c.Request().Body, maxBodyLen)
		return json.NewDecoder(reader).Decode(v)
	}
	return nil
}

// ValidateStruct validates the struct fields based on the `validate` tag.
func ValidateStruct(c echo.Context, v any) error {
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		tagValue := fieldType.Tag.Get("validate")

		if tagValue != "" {
			if err := validateField(field, tagValue); err != nil {
				return fmt.Errorf("field %s: %w", fieldType.Name, err)
			}
		}
	}

	return nil
}

// Utility functions

func parseTags(getValue func(string) string, tagKey string, v any) error {
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		tagValue := fieldType.Tag.Get(tagKey)

		if tagValue != "" && getValue != nil {
			val := getValue(tagValue)
			if val != "" {
				if err := setFieldValue(field, val); err != nil {
					return fmt.Errorf("error setting %s %s: %w", tagKey, tagValue, err)
				}
			}
		} else if tagKey == "validate" {
			// Validate field based on `validate` tag
			if err := validateField(field, tagValue); err != nil {
				return fmt.Errorf("field %s: %w", fieldType.Name, err)
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
			paramName := strings.TrimPrefix(part[strings.Index(part, ":"):], ":")
			prefix := part[:strings.Index(part, ":")]
			if strings.HasPrefix(actualParts[actualIndex], prefix) {
				vars[paramName] = strings.TrimPrefix(actualParts[actualIndex], prefix)
			} else {
				return nil, fmt.Errorf("path does not match pattern: expected %s, got %s", pattern, actualPath)
			}
		} else if part != actualParts[actualIndex] {
			return nil, fmt.Errorf("path does not match pattern: expected %s, got %s", pattern, actualPath)
		}
	}

	return vars, nil
}

func setFieldValues(vars map[string]string, tagKey string, v any) error {
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		tagValue := fieldType.Tag.Get(tagKey)

		if tagValue != "" {
			if pathValue, ok := vars[tagValue]; ok {
				if err := setFieldValue(field, pathValue); err != nil {
					return fmt.Errorf("error setting path parameter %s: %w", tagValue, err)
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

func withJsonBody(r *http.Request) bool {
	return r.ContentLength > 0 && strings.Contains(r.Header.Get("Content-Type"), "application/json")
}

// validateField validates a single field based on the `validate` tag.
func validateField(field reflect.Value, tag string) error {
	tags := strings.Split(tag, ",")

	for _, t := range tags {
		if t == "required" && isEmpty(field) {
			return errors.New("is required")
		}

		if t == "email" {
			if !isValidEmail(field.String()) {
				return fmt.Errorf("%s does not validate as email", field.String())
			}
		}

		if strings.HasPrefix(t, "min=") {
			min, err := strconv.Atoi(strings.TrimPrefix(t, "min="))
			if err != nil {
				return err
			}

			if len(field.String()) < min {
				return fmt.Errorf("minimum length is %d", min)
			}
		}

		if strings.HasPrefix(t, "max=") {
			max, err := strconv.Atoi(strings.TrimPrefix(t, "max="))
			if err != nil {
				return err
			}

			if len(field.String()) > max {
				return fmt.Errorf("maximum length is %d", max)
			}
		}
	}

	return nil
}

func isValidEmail(email string) bool {
	// This is a simple check. For production use, consider using a more robust regex or a dedicated email validation library.
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}

// isEmpty checks if a value is considered empty.
func isEmpty(field reflect.Value) bool {
	switch field.Kind() {
	case reflect.String:
		return field.Len() == 0
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return field.Int() == 0
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return field.Uint() == 0
	case reflect.Float32, reflect.Float64:
		return field.Float() == 0
	case reflect.Bool:
		return !field.Bool()
	case reflect.Slice, reflect.Map, reflect.Array, reflect.Chan, reflect.Interface, reflect.Ptr:
		return field.IsNil()
	}
	return false
}

// SetValidator sets the validator.
func SetValidator(val Validator) {
	validator.Store(val)
}
