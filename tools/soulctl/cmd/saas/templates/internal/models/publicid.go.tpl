package models

import (
	"context"
	"database/sql/driver"
	"errors"

	"github.com/rs/xid"
)

type PublicID string

func NewPublicID(db SqlxDB, table string) PublicID {
	var publicID PublicID

	query := `
		WITH RECURSIVE new_id AS (
			SELECT new_public_id() AS public_id
			UNION
			SELECT new_public_id()
			FROM new_id
			WHERE EXISTS (
				SELECT 1
				FROM ` + table + `
				WHERE public_id = new_id.public_id
			)
		)
		SELECT public_id
		FROM new_id
		WHERE NOT EXISTS (
			SELECT 1
			FROM ` + table + `
			WHERE public_id = new_id.public_id
		)
		LIMIT 1;
	`

	err := db.GetContext(context.Background(), &publicID, query)
	if err != nil {
		// Use xid as a fallback and truncate it to 11 characters
		guid := xid.New().String()
		publicID = PublicID(guid[:11])
	}

	return publicID
}

// String returns a string representation of the PublicID
func (s PublicID) String() string {
	return string(s)
}

// NullPublicID represents a PublicID that may be null.
type NullPublicID struct {
	PublicID PublicID
	Valid    bool
}

// NewNullPublicID creates a new NullPublicID from a non-pointer PublicID
func NewNullPublicID(db SqlxDB, table string) NullPublicID {
	id := NewPublicID(db, table)
	return NullPublicID{
		PublicID: id,
		Valid:    id != "",
	}
}

func ToNullPublicID(id PublicID) NullPublicID {
	return NullPublicID{
		PublicID: id,
		Valid:    id != "",
	}
}

// String returns a string representation of the NullPublicID if valid, otherwise an empty string.
func (n NullPublicID) String() string {
	if n.Valid {
		return n.PublicID.String()
	}
	return ""
}

// Value implements the driver.Valuer interface
func (n NullPublicID) Value() (driver.Value, error) {
	if !n.Valid {
		return nil, nil
	}
	return n.PublicID.String(), nil
}

// Scan implements the sql.Scanner interface
func (n *NullPublicID) Scan(value interface{}) error {
	if value == nil {
		n.PublicID, n.Valid = "", false
		return nil
	}
	n.Valid = true
	switch v := value.(type) {
	case string:
		n.PublicID = PublicID(v)
	case []byte:
		n.PublicID = PublicID(string(v))
	default:
		return errors.New("unsupported data type for PublicID")
	}
	return nil
}
