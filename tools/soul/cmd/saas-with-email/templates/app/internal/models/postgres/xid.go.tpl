package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"

	"github.com/rs/xid"
)

// Xid is a custom type that wraps xid.ID and includes a validity flag for nullability.
type Xid struct {
	ID    xid.ID
	Valid bool // Valid is true if the Xid is not NULL
}

// NewXid creates a new valid Xid.
func NewXid() Xid {
	return Xid{
		ID:    xid.New(),
		Valid: true,
	}
}

// NewNullXid creates a new null Xid.
func NewNullXid() Xid {
	return Xid{
		ID:    xid.ID{},
		Valid: false,
	}
}

func ToXid(id string) Xid {
	sXid, _ := xid.FromString(id)
	return Xid{
		ID:    sXid,
		Valid: true,
	}
}

// MarshalJSON implements the json.Marshaler interface.
func (x Xid) MarshalJSON() ([]byte, error) {
	if !x.Valid {
		return json.Marshal(nil)
	}
	return json.Marshal(x.ID.String())
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (x *Xid) UnmarshalJSON(b []byte) error {
	var s *string
	if err := json.Unmarshal(b, &s); err != nil {
		return err
	}
	if s == nil {
		x.Valid = false
		return nil
	}
	id, err := xid.FromString(*s)
	if err != nil {
		return err
	}
	x.ID = id
	x.Valid = true
	return nil
}

// Scan implements the sql.Scanner interface.
func (x *Xid) Scan(value interface{}) error {
	if value == nil {
		x.ID, x.Valid = xid.ID{}, false
		return nil
	}
	x.Valid = true
	switch v := value.(type) {
	case []byte:
		return x.ID.UnmarshalText(v)
	case string:
		return x.ID.UnmarshalText([]byte(v))
	default:
		return fmt.Errorf("cannot scan type %T into Xid: %v", value, value)
	}
}

// Value implements the driver.Valuer interface.
func (x Xid) Value() (driver.Value, error) {
	if !x.Valid {
		return nil, nil
	}
	return x.ID.String(), nil
}

// String returns the string representation of the Xid, or "null" if invalid.
func (x Xid) String() string {
	if !x.Valid {
		return "null"
	}
	return x.ID.String()
}

// NullXid is an alias for Xid, used to indicate that the ID is nullable.
type NullXid Xid

// NewNullXidAlias creates a new valid NullXid.
func NewNullXidAlias() NullXid {
	return NullXid(NewXid())
}

// NewInvalidNullXidAlias creates a new invalid NullXid (null value).
func NewInvalidNullXidAlias() NullXid {
	return NullXid(NewNullXid())
}

// Scan implements the sql.Scanner interface for NullXid.
func (nx *NullXid) Scan(value interface{}) error {
	if value == nil {
		nx.ID, nx.Valid = xid.ID{}, false
		return nil
	}
	nx.Valid = true
	switch v := value.(type) {
	case []byte:
		return nx.ID.UnmarshalText(v)
	case string:
		return nx.ID.UnmarshalText([]byte(v))
	default:
		return fmt.Errorf("cannot scan type %T into NullXid: %v", value, value)
	}
}

// Value implements the driver.Valuer interface for NullXid.
func (nx NullXid) Value() (driver.Value, error) {
	if !nx.Valid {
		return nil, nil
	}
	return nx.ID.String(), nil
}

// MarshalJSON implements the json.Marshaler interface for NullXid.
func (nx NullXid) MarshalJSON() ([]byte, error) {
	if !nx.Valid {
		return json.Marshal(nil)
	}
	return json.Marshal(nx.ID.String())
}

// UnmarshalJSON implements the json.Unmarshaler interface for NullXid.
func (nx *NullXid) UnmarshalJSON(b []byte) error {
	var s *string
	if err := json.Unmarshal(b, &s); err != nil {
		return err
	}
	if s == nil {
		nx.Valid = false
		return nil
	}
	id, err := xid.FromString(*s)
	if err != nil {
		return err
	}
	nx.ID = id
	nx.Valid = true
	return nil
}
