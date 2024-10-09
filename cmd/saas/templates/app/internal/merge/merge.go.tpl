package merge

import (
	"fmt"
	"reflect"
	"time"

	"{{ .serviceName }}/internal/types" // Update with the actual package path
)

// New merges non-zero fields from form into db based on matching tags, preserving ID and leaving missing fields unchanged.
func New[F any, D any](form F, db *D) error {
	formVal := reflect.ValueOf(form)
	if formVal.Kind() == reflect.Ptr {
		formVal = formVal.Elem()
	}

	dbVal := reflect.ValueOf(db)
	if dbVal.Kind() == reflect.Ptr {
		dbVal = dbVal.Elem()
	}

	// Check if form and db are structs
	if formVal.Kind() != reflect.Struct {
		return fmt.Errorf("form is not a struct")
	}
	if dbVal.Kind() != reflect.Struct {
		return fmt.Errorf("db is not a struct")
	}

	formType := formVal.Type()
	dbType := dbVal.Type()

	for i := 0; i < formType.NumField(); i++ {
		formField := formVal.Field(i)
		formTag := formType.Field(i).Tag.Get("form")

		if formTag == "" {
			continue
		}

		dbField := findFieldByTag(dbVal, dbType, "db", formTag)
		if !dbField.IsValid() || !dbField.CanSet() {
			continue
		}

		switch formField.Kind() {
		case reflect.String:
			// Handle string conversion
			if dbField.Type() == reflect.TypeOf(types.NewNullString("")) {
				dbField.Set(reflect.ValueOf(types.NewNullString(formField.String())))
			} else {
				dbField.Set(formField)
			}
		case reflect.Int, reflect.Int32, reflect.Int64:
			if formField.Int() != 0 {
				if dbField.Type() == reflect.TypeOf(types.NewNullInt64(0)) {
					dbField.Set(reflect.ValueOf(types.NewNullInt64(formField.Int())))
				} else {
					dbField.Set(formField)
				}
			}
		case reflect.Bool:
			if dbField.Type() == reflect.TypeOf(types.NewNullBool(false)) {
				dbField.Set(reflect.ValueOf(types.NewNullBool(formField.Bool())))
			} else {
				dbField.Set(formField)
			}
		case reflect.Struct:
			if formField.Type() == reflect.TypeOf(time.Time{}) {
				if dbField.Type() == reflect.TypeOf(types.NewNullTime(time.Time{})) {
					dbField.Set(reflect.ValueOf(types.NewNullTime(formField.Interface().(time.Time))))
				} else {
					dbField.Set(formField)
				}
			}
		case reflect.Ptr:
			if !formField.IsNil() {
				elemType := formField.Elem().Type()
				switch elemType.Kind() {
				case reflect.String:
					if dbField.Type() == reflect.TypeOf(types.NewNullString("")) {
						dbField.Set(reflect.ValueOf(types.NewNullString(formField.Elem().String())))
					} else {
						dbField.Set(formField.Elem())
					}
				case reflect.Int, reflect.Int32, reflect.Int64:
					if dbField.Type() == reflect.TypeOf(types.NewNullInt64(0)) {
						dbField.Set(reflect.ValueOf(types.NewNullInt64(formField.Elem().Int())))
					} else {
						dbField.Set(formField.Elem())
					}
				case reflect.Bool:
					if dbField.Type() == reflect.TypeOf(types.NewNullBool(false)) {
						dbField.Set(reflect.ValueOf(types.NewNullBool(formField.Elem().Bool())))
					} else {
						dbField.Set(formField.Elem())
					}
				case reflect.Struct:
					if elemType == reflect.TypeOf(time.Time{}) {
						if dbField.Type() == reflect.TypeOf(types.NewNullTime(time.Time{})) {
							dbField.Set(reflect.ValueOf(types.NewNullTime(formField.Elem().Interface().(time.Time))))
						} else {
							dbField.Set(formField.Elem())
						}
					}
				}
			}
		}
	}

	return nil
}

// findFieldByTag finds a field in a struct based on the given tag and value.
func findFieldByTag(v reflect.Value, t reflect.Type, tag, value string) reflect.Value {
	for i := 0; i < t.NumField(); i++ {
		if t.Field(i).Tag.Get(tag) == value {
			return v.Field(i)
		}
	}
	return reflect.Value{}
}
