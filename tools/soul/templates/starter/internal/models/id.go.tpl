package models

import (
	"fmt"
)

func NewID(db SqlxDB, prefix ...string) string {
	if len(prefix) == 0 {
		prefix = append(prefix, "r")
	}
	sql := fmt.Sprintf(`select ('%s' || lower(hex (randomblob (7)))) as id`, prefix[0])
	var id string
	_ = db.Get(&id, sql)
	return id
}
