package httpx

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"reflect"
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

// Validator defines the interface for validating the request.
type Validator interface {
	// Validate validates the request and parsed data.
	Validate(c echo.Context, data any) error
}

var validator atomic.Value

// Parse handles the complete parsing of an HTTP request, processing path parameters,
// query parameters, form data, headers, and JSON body. It also validates the parsed data
// if a validator is configured.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where parsed data will be stored
//   - pattern: The URL pattern for path parameter extraction
//
// The target struct can use the following tags:
//   - `path:"name"` or `path:"name,optional"` for path parameters
//   - `query:"name"` or `query:"name,optional"` for query parameters
//   - `form:"name"` or `form:"name,optional"` for form data
//   - `file:"name"` or `file:"name,optional"` for file metadata
//   - `header:"name"` or `header:"name,optional"` for headers
//
// Returns an error if parsing fails or validation fails.
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

// ParseHeaders extracts and parses HTTP headers into the target struct.
// Headers are mapped using the "header" struct tag.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where header values will be stored
//
// Header fields can be marked as optional using the "optional" tag modifier:
//
//	type Headers struct {
//	    Auth string `header:"Authorization"`           // required
//	    Track string `header:"X-Tracking,optional"`   // optional
//	}
//
// Returns an error if a required header is missing or if type conversion fails.
func ParseHeaders(c echo.Context, v any) error {
	headers := c.Request().Header
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		headerTag := fieldType.Tag.Get("header")

		if headerTag != "" {
			tagParts := strings.Split(headerTag, ",")
			headerName := tagParts[0]
			isOptional := len(tagParts) > 1 && tagParts[1] == "optional"

			headerValue := headers.Get(headerName)
			if headerValue != "" {
				if err := setFieldValue(field, headerValue); err != nil {
					return fmt.Errorf("error setting header parameter %s: %w", headerName, err)
				}
			} else if !isOptional {
				return fmt.Errorf("missing required header parameter: %s", headerName)
			}
		}
	}

	return nil
}

// ParseForm handles both regular form data and multipart form data, including file uploads.
// Form values are mapped using the "form" struct tag, and file metadata using the "file" tag.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where form values will be stored
//
// Supports both single values and slices. Fields can be marked as optional:
//
//	type FormData struct {
//	    Name   string   `form:"name"`            // required field
//	    Tags   []string `form:"tags,optional"`   // optional slice
//	    File   string   `file:"upload"`          // required file
//	    Size   int64    `file:"upload,optional"` // optional file metadata
//	}
//
// Returns an error if parsing fails, a required field is missing, or type conversion fails.
func ParseForm(c echo.Context, v any) error {
	// Check if the request is multipart
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

	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		formTag := fieldType.Tag.Get("form")

		if formTag != "" {
			tagParts := strings.Split(formTag, ",")
			formName := tagParts[0]
			isOptional := len(tagParts) > 1 && tagParts[1] == "optional"

			var formValues []string
			if isMultipart {
				formValues = c.Request().MultipartForm.Value[formName]
			} else {
				formValues = c.Request().Form[formName]
			}

			if len(formValues) > 0 {
				if field.Kind() == reflect.Slice {
					slice := reflect.MakeSlice(field.Type(), 0, len(formValues))
					for _, formValue := range formValues {
						newElem := reflect.New(field.Type().Elem()).Elem()
						if err := setFieldValue(newElem, formValue); err != nil {
							return fmt.Errorf("error setting form value %s: %w", formName, err)
						}
						slice = reflect.Append(slice, newElem)
					}
					field.Set(slice)
				} else {
					if err := setFieldValue(field, formValues[0]); err != nil {
						return fmt.Errorf("error setting form value %s: %w", formName, err)
					}
				}
			} else if !isOptional {
				return fmt.Errorf("missing required form parameter: %s", formName)
			}
		}

		fileTag := fieldType.Tag.Get("file")
		if isMultipart && fileTag != "" {
			tagParts := strings.Split(fileTag, ",")
			fileName := tagParts[0]
			isOptional := len(tagParts) > 1 && tagParts[1] == "optional"

			fileHeader, err := c.FormFile(fileName)
			if err == nil && fileHeader != nil {
				switch fieldType.Name {
				case "Filename":
					field.SetString(fileHeader.Filename)
				case "FileSize":
					field.SetInt(fileHeader.Size)
				case "ContentType":
					field.SetString(fileHeader.Header.Get("Content-Type"))
				}
			} else if !isOptional {
				return fmt.Errorf("missing required file parameter: %s", fileName)
			}
		}
	}

	return nil
}

// ParseHeader parses a single header value that contains key-value pairs
// separated by semicolons and returns them as a map.
//
// Parameter:
//   - headerValue: Raw header string in the format "key1=value1;key2=value2"
//
// Returns a map of the parsed key-value pairs.
// Example input: "token=abc123;expire=3600"
// Returns: map[string]string{"token": "abc123", "expire": "3600"}
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

// ParseJsonBody decodes JSON data from the request body into the target struct.
// Only processes the request if Content-Type is application/json.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where JSON data will be decoded
//
// ParseJsonBody extracts and parses the JSON body of an HTTP request into the target struct.
// The body size is limited to maxBodyLen (8MB) to prevent memory exhaustion.
// Returns an error if JSON decoding fails.
func ParseJsonBody(c echo.Context, v any) error {
	if withJsonBody(c.Request()) {
		// Create a buffer to store the body
		var bodyBuffer bytes.Buffer

		// Use TeeReader to read the body while simultaneously copying it to the buffer
		// This also applies the maxBodyLen limit to prevent memory exhaustion
		teeReader := io.TeeReader(io.LimitReader(c.Request().Body, maxBodyLen), &bodyBuffer)

		// Decode the JSON directly from the teeReader
		err := json.NewDecoder(teeReader).Decode(v)

		// Restore the body for later use
		c.Request().Body = io.NopCloser(&bodyBuffer)

		return err
	}

	return nil
}

// ParsePath extracts and parses URL path parameters into the target struct.
// Path parameters are mapped using the "path" struct tag.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where path values will be stored
//   - pattern: The URL pattern for parameter extraction
//
// Supports both simple and embedded parameters. Fields can be marked as optional:
//
//	type PathParams struct {
//	    ID   string `path:"id"`            // required
//	    Slug string `path:"slug,optional"` // optional
//	}
//
// Returns an error if parsing fails, a required parameter is missing, or type conversion fails.
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
			tagParts := strings.Split(pathTag, ",")
			pathName := tagParts[0]
			isOptional := len(tagParts) > 1 && tagParts[1] == "optional"

			var paramValue string
			if value, ok := vars[pathName]; ok {
				paramValue = value
			} else {
				paramValue = c.Param(pathName)
			}

			if paramValue != "" {
				if err := setFieldValue(field, paramValue); err != nil {
					return fmt.Errorf("error setting path parameter %s: %w", pathName, err)
				}
			} else if !isOptional {
				return fmt.Errorf("missing required path parameter: %s", pathName)
			}
		}
	}

	return nil
}

// extractPathVars extracts path variables from the URL based on the given pattern.
// Handles both regular path parameters and embedded parameters.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - pattern: The URL pattern to match against
//
// Returns a map of parameter names to their values and an error if pattern matching fails.
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

// extractParamNames extracts parameter names from a URL path part that contains
// embedded parameters.
//
// Parameter:
//   - part: A single segment of a URL path that may contain embedded parameters
//
// Returns a slice of parameter names found in the path part.
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

// ParseQuery extracts and parses URL query parameters into the target struct.
// Query parameters are mapped using the "query" struct tag.
//
// Parameters:
//   - c: The Echo context containing the HTTP request
//   - v: A pointer to the struct where query values will be stored
//
// Query fields can be marked as optional using the "optional" tag modifier:
//
//	type QueryParams struct {
//	    Page  int    `query:"page"`           // required
//	    Size  int    `query:"size,optional"`  // optional
//	    Sort  string `query:"sort,optional"`  // optional
//	}
//
// Returns an error if a required parameter is missing or if type conversion fails.
func ParseQuery(c echo.Context, v any) error {
	queryParams := c.QueryParams()
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		queryTag := fieldType.Tag.Get("query")

		if queryTag != "" {
			tagParts := strings.Split(queryTag, ",")
			queryName := tagParts[0]
			isOptional := len(tagParts) > 1 && tagParts[1] == "optional"

			queryValue := queryParams.Get(queryName)
			if queryValue != "" {
				if err := setFieldValue(field, queryValue); err != nil {
					return fmt.Errorf("error setting query parameter %s: %w", queryName, err)
				}
			} else if !isOptional {
				return fmt.Errorf("missing required query parameter: %s", queryName)
			}
		}
	}

	return nil
}

// setFieldValue sets a reflected field's value from a string input.
// Supports multiple types including basic types, time.Time, slices, and maps.
//
// Parameters:
//   - field: The reflected field to set
//   - value: The string value to parse and set
//
// Supported types:
//   - String
//   - Int, Int8, Int16, Int32, Int64
//   - Uint, Uint8, Uint16, Uint32, Uint64
//   - Float32, Float64
//   - Bool
//   - time.Time (RFC3339 format)
//   - []string (comma-separated values)
//   - map[string]string (JSON format)
//
// Returns an error if type conversion fails or if the field type is unsupported.
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
	case reflect.Struct:
		if field.Type() == reflect.TypeOf(time.Time{}) {
			timeValue, err := time.Parse(time.RFC3339, value)
			if err != nil {
				return err
			}
			field.Set(reflect.ValueOf(timeValue))
		} else {
			return fmt.Errorf("unsupported struct type: %s", field.Type().String())
		}
	case reflect.Slice:
		// Handle slice types (assuming string slice for now)
		if field.Type().Elem().Kind() == reflect.String {
			values := strings.Split(value, ",")
			slice := reflect.MakeSlice(field.Type(), len(values), len(values))
			for i, v := range values {
				slice.Index(i).SetString(v)
			}
			field.Set(slice)
		} else {
			return fmt.Errorf("unsupported slice type: %s", field.Type().Elem().String())
		}
	case reflect.Map:
		// Handle map types (assuming string to string map for now)
		if field.Type().Key().Kind() == reflect.String && field.Type().Elem().Kind() == reflect.String {
			var mapValue map[string]string
			if err := json.Unmarshal([]byte(value), &mapValue); err != nil {
				return err
			}
			field.Set(reflect.ValueOf(mapValue))
		} else {
			return fmt.Errorf("unsupported map type: %s", field.Type().String())
		}
	default:
		return fmt.Errorf("unsupported field type: %s", field.Kind().String())
	}
	return nil
}

// SetValidator configures the validator used for validating parsed data.
// The validator is only called during the Parse function, not in individual parse functions.
//
// Parameter:
//   - val: Implementation of the Validator interface
func SetValidator(val Validator) {
	validator.Store(val)
}

// withJsonBody checks if the request contains JSON data based on Content-Type
// and Content-Length headers.
//
// Parameter:
//   - r: The HTTP request to check
//
// Returns true if the request contains JSON data.
func withJsonBody(r *http.Request) bool {
	return r.ContentLength > 0 && strings.Contains(r.Header.Get("Content-Type"), "application/json")
}
