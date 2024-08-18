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
	Validate(r *http.Request, data any) error
}

var validator atomic.Value

// Parse parses the request.
func Parse(r *http.Request, v any, pattern string) error {
	if err := ParsePath(r, v, pattern); err != nil {
		return err
	}

	if err := ParseQuery(r, v); err != nil {
		return err
	}

	if err := ParseForm(r, v); err != nil {
		return err
	}

	if err := ParseHeaders(r, v); err != nil {
		return err
	}

	if err := ParseJsonBody(r, v); err != nil {
		return err
	}

	if err := ValidateStruct(v); err != nil {
		return err
	}

	if valid, ok := v.(Validator); ok {
		return valid.Validate(r, v)
	} else if val := validator.Load(); val != nil {
		return val.(Validator).Validate(r, v)
	}

	return nil
}

// ParseHeaders parses the headers request.
func ParseHeaders(r *http.Request, v any) error {
	headers := r.Header
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
func ParseForm(r *http.Request, v any) error {
	if err := r.ParseForm(); err != nil {
		return err
	}

	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		formTag := fieldType.Tag.Get("form")

		if formTag != "" {
			formValue := r.FormValue(formTag)
			if formValue != "" {
				if field.Kind() == reflect.String {
					field.SetString(formValue)
				} else {
					return fmt.Errorf("unsupported field type: %s", field.Kind().String())
				}
				// fmt.Printf("Set field %s to value %s\n", fieldType.Name, formValue)
			}
			// else {
			// 	fmt.Printf("Form value for tag %s is empty\n", formTag)
			// }
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
func ParseJsonBody(r *http.Request, v any) error {
	if withJsonBody(r) {
		reader := io.LimitReader(r.Body, maxBodyLen)
		return json.NewDecoder(reader).Decode(v)
	}

	return nil
}

// ParsePath parses the symbols residing in the URL path.
func ParsePath(r *http.Request, v any, pattern string) error {
	path := r.URL.Path
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	parts := strings.Split(path, "/")
	patternParts := strings.Split(pattern, "/")

	// fmt.Println("        PARTS:", parts)
	// fmt.Println("PATTERN PARTS:", patternParts)

	// Align from the end of the path and the pattern
	vars := map[string]string{}
	partsLen := len(parts)
	patternLen := len(patternParts)

	if partsLen < patternLen {
		return errors.New("path does not match pattern")
	}

	for i := 0; i < patternLen; i++ {
		part := patternParts[patternLen-i-1]
		if strings.HasPrefix(part, ":") {
			varName := part[1:]
			vars[varName] = parts[partsLen-i-1]
		}
	}

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		pathTag := fieldType.Tag.Get("path")

		if pathTag != "" {
			if pathValue, ok := vars[pathTag]; ok {
				field.SetString(pathValue)
			}
		}
	}

	return nil
}

func ParseQuery(r *http.Request, v any) error {
	queryParams := r.URL.Query()
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

// ValidateStruct validates the struct fields based on the `validate` tag.
func ValidateStruct(v any) error {
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		validateTag := fieldType.Tag.Get("validate")
		optionalTag := fieldType.Tag.Get("optional")

		if optionalTag == "" {
			// Required by default if no `optional` tag is present
			validateTag = "required," + validateTag
		}

		if err := validateField(field, validateTag); err != nil {
			return fmt.Errorf("field %s: %w", fieldType.Name, err)
		}
	}

	return nil
}

// validateField validates a single field based on the `validate` tag.
func validateField(field reflect.Value, tag string) error {
	tags := strings.Split(tag, ",")

	for _, t := range tags {
		if t == "required" && isEmpty(field) {
			return errors.New("is required")
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
