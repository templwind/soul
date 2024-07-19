//go:build !cgo && sqlite

package db

import (
	_ "modernc.org/sqlite"
)
