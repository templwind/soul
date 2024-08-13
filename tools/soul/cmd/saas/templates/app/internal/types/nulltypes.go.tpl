package types

import (
	"database/sql"
	"time"
)

func NewNullString(value interface{}) sql.NullString {
	n := sql.NullString{}
	switch t := value.(type) {
	case string:
		n.String = t
		n.Valid = true
	case *string:
		n.Valid = t != nil
		if n.Valid {
			n.String = *t
		}
	}
	return n
}

func NewStringFromNull(value sql.NullString) string {
	if value.Valid {
		return value.String
	}
	return ""
}

func NewStringPtr(value string) *string {
	return &value
}

func NewNullInt64(value interface{}) sql.NullInt64 {
	n := sql.NullInt64{}

	switch t := value.(type) {
	case int64:
		n.Int64 = t
		n.Valid = true
	case int32:
		// Convert int32 to int64
		n.Int64 = int64(t)
		n.Valid = true
	case int:
		// Convert int to int64 (assuming it's safe to do so)
		n.Int64 = int64(t)
		n.Valid = true
	case *int64:
		n.Valid = t != nil
		if n.Valid {
			n.Int64 = *t
		}
	case *int32:
		// Convert pointer of int32 to int64
		if t != nil {
			n.Int64 = int64(*t)
			n.Valid = true
		}
	case *int:
		// Convert pointer of int to int64
		if t != nil {
			n.Int64 = int64(*t)
			n.Valid = true
		}
	}

	return n
}

func NewInt64FromNull(value sql.NullInt64) int64 {
	if value.Valid {
		return value.Int64
	}
	return 0
}

func NewInt64Ptr(value int64) *int64 {
	return &value
}

func NewNullInt32(value interface{}) sql.NullInt32 {
	n := sql.NullInt32{}

	switch t := value.(type) {
	case int32:
		n.Int32 = t
		n.Valid = true
	case int:
		// Convert int to int32 (assuming it's safe to do so)
		n.Int32 = int32(t)
		n.Valid = true
	case int64:
		// Convert int64 to int32 (assuming it's safe to do so)
		n.Int32 = int32(t)
		n.Valid = true
	case *int32:
		n.Valid = t != nil
		if n.Valid {
			n.Int32 = *t
		}
	case *int:
		// Convert pointer of int to int32
		if t != nil {
			n.Int32 = int32(*t)
			n.Valid = true
		}
	case *int64:
		// Convert pointer of int64 to int32
		if t != nil {
			n.Int32 = int32(*t)
			n.Valid = true
		}
	}

	return n
}

func NewInt32FromNull(value sql.NullInt32) int32 {
	if value.Valid {
		return value.Int32
	}
	return 0
}

func NewInt32Ptr(value int32) *int32 {
	return &value
}

func NewNullBool(value interface{}) sql.NullBool {
	n := sql.NullBool{}

	switch t := value.(type) {
	case bool:
		n.Bool = t
		n.Valid = true
	case int:
		// Convert non-zero int to true, zero to false
		n.Bool = (t != 0)
		n.Valid = true
	case *bool:
		n.Valid = t != nil
		if n.Valid {
			n.Bool = *t
		}
	case *int:
		// Convert pointer of int to bool
		if t != nil {
			n.Bool = (*t != 0)
			n.Valid = true
		}
	}

	return n
}

func NewBoolFromNull(value sql.NullBool) bool {
	if value.Valid {
		return value.Bool
	}
	return false
}

func NewBoolPtr(value bool) *bool {
	return &value
}

// NewNullTime creates a new sql.NullTime from a time.Time or *time.Time value.
func NewNullTime(value interface{}) sql.NullTime {
	n := sql.NullTime{}
	switch t := value.(type) {
	case time.Time:
		n.Time = t
		n.Valid = true
	case *time.Time:
		n.Valid = t != nil
		if n.Valid {
			n.Time = *t
		}
	}
	return n
}

// NewTimeFromNull returns a time.Time value from a sql.NullTime.
// If the NullTime is not valid, it returns the zero value of time.Time.
func NewTimeFromNull(value sql.NullTime) time.Time {
	if value.Valid {
		return value.Time
	}
	return time.Time{}
}

// NewTimePtr returns a pointer to a time.Time value.
func NewTimePtr(value time.Time) *time.Time {
	return &value
}
