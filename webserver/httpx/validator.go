package httpx

import (
	"errors"
	"fmt"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"unicode"
)

// ValidateStruct validates the struct fields based on the `validate` tag.
func ValidateStruct(v any) error {
	val := reflect.ValueOf(v).Elem()
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		field := val.Field(i)
		fieldType := typ.Field(i)
		validateTag := fieldType.Tag.Get("validate")

		// Check if the field is optional
		isOptional := isFieldOptional(fieldType)

		// If it's not optional and not specified in the path, add required validation
		if !isOptional && fieldType.Tag.Get("path") == "" {
			validateTag = addRequiredValidation(validateTag)
		}

		if err := validateField(field, validateTag); err != nil {
			return fmt.Errorf("field %s: %w", fieldType.Name, err)
		}
	}

	return nil
}

// isFieldOptional checks if the field is marked as optional in any of its tags
func isFieldOptional(fieldType reflect.StructField) bool {
	tags := []string{"query", "form", "json", "header"}
	for _, tag := range tags {
		tagValue := fieldType.Tag.Get(tag)
		if strings.Contains(tagValue, "optional") {
			return true
		}
	}
	return false
}

// addRequiredValidation adds the "required" validation if it's not already present
func addRequiredValidation(validateTag string) string {
	if validateTag == "" {
		return "required"
	}
	if !strings.Contains(validateTag, "required") {
		return "required," + validateTag
	}
	return validateTag
}

// validateField validates a single field based on the `validate` tag.
func validateField(field reflect.Value, tag string) error {
	tags := strings.Split(tag, ",")

	for _, t := range tags {
		switch {
		case t == "required":
			if isEmpty(field) {
				return errors.New("is required")
			}
		case t == "email":
			if !isValidEmail(field.String()) {
				return fmt.Errorf("%s does not validate as email", field.String())
			}
		case t == "creditcard":
			if !isValidCreditCard(field.String()) {
				return errors.New("invalid credit card number")
			}
		case t == "alphanum":
			if !isAlphanumeric(field.String()) {
				return errors.New("must be alphanumeric")
			}
		case t == "url":
			if !isValidURL(field.String()) {
				return errors.New("invalid URL")
			}
		case strings.HasPrefix(t, "min="):
			min, err := strconv.Atoi(strings.TrimPrefix(t, "min="))
			if err != nil {
				return err
			}
			if len(field.String()) < min {
				return fmt.Errorf("minimum length is %d", min)
			}
		case strings.HasPrefix(t, "max="):
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
	pattern := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	match, _ := regexp.MatchString(pattern, email)
	return match
}

func isValidCreditCard(number string) bool {
	// Remove any non-digit characters
	number = regexp.MustCompile(`\D`).ReplaceAllString(number, "")

	// Check if the number is between 13 and 19 digits
	if len(number) < 13 || len(number) > 19 {
		return false
	}

	// Luhn algorithm
	sum := 0
	isEven := false
	for i := len(number) - 1; i >= 0; i-- {
		digit := int(number[i] - '0')
		if isEven {
			digit *= 2
			if digit > 9 {
				digit -= 9
			}
		}
		sum += digit
		isEven = !isEven
	}
	return sum%10 == 0
}

func isAlphanumeric(s string) bool {
	for _, r := range s {
		if !unicode.IsLetter(r) && !unicode.IsNumber(r) {
			return false
		}
	}
	return true
}

func isValidURL(url string) bool {
	pattern := `^(http|https)://[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[\w\-\./?%&=]*)?$`
	match, _ := regexp.MatchString(pattern, url)
	return match
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
