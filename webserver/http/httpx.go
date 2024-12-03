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
// ParseForm parses the form request, including multipart form data.
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
			var formValues []string
			if isMultipart {
				formValues = c.Request().MultipartForm.Value[formTag]
			} else {
				formValues = c.Request().Form[formTag]
			}

			if len(formValues) > 0 {
				if field.Kind() == reflect.Slice {
					slice := reflect.MakeSlice(field.Type(), 0, len(formValues))
					for _, formValue := range formValues {
						newElem := reflect.New(field.Type().Elem()).Elem()
						if err := setFieldValue(newElem, formValue); err != nil {
							return fmt.Errorf("error setting form value %s: %w", formTag, err)
						}
						slice = reflect.Append(slice, newElem)
					}
					field.Set(slice)
				} else {
					if err := setFieldValue(field, formValues[0]); err != nil {
						return fmt.Errorf("error setting form value %s: %w", formTag, err)
					}
				}
			}
		}
	}

	// Handle file metadata if present
	if isMultipart {
		fileHeader, err := c.FormFile("file")
		if err == nil && fileHeader != nil {
			if filenameField := val.FieldByName("Filename"); filenameField.IsValid() && filenameField.CanSet() {
				filenameField.SetString(fileHeader.Filename)
			}
			if fileSizeField := val.FieldByName("FileSize"); fileSizeField.IsValid() && fileSizeField.CanSet() {
				fileSizeField.SetInt(fileHeader.Size)
			}
			if contentTypeField := val.FieldByName("ContentType"); contentTypeField.IsValid() && contentTypeField.CanSet() {
				contentTypeField.SetString(fileHeader.Header.Get("Content-Type"))
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
			var paramValue string
			if value, ok := vars[pathTag]; ok {
				paramValue = value
			} else {
				paramValue = c.Param(pathTag)
			}

			if paramValue != "" {
				if err := setFieldValue(field, paramValue); err != nil {
					return fmt.Errorf("error setting path parameter %s: %w", pathTag, err)
				}
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

// Add support for time.Time in setFieldValue
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

// SetValidator sets the validator.
// The validator is used to validate the request, only called in Parse,
// not in ParseHeaders, ParseForm, ParseHeader, ParseJsonBody, ParsePath.
func SetValidator(val Validator) {
	validator.Store(val)
}

func withJsonBody(r *http.Request) bool {
	return r.ContentLength > 0 && strings.Contains(r.Header.Get("Content-Type"), "application/json")
}
