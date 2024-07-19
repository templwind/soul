//go:build !cgo

package db

import (
	"github.com/jmoiron/sqlx"
	_ "modernc.org/sqlite"
	"github.com/xo/dburl"
)

func connect(dsn string) (*sqlx.DB, error) {
	u, err := dburl.Parse(dsn)
	if err != nil {
		return nil, err
	}

	// For SQLite, u.DSN gives the path to the database file.
	dbConn, err := sqlx.Connect(u.Driver, u.DSN)
	if err != nil {
		return nil, err
	}

	// Enable WAL mode
	_, err = dbConn.Exec("PRAGMA journal_mode = WAL;")
	if err != nil {
		return nil, err
	}

	return dbConn, nil
}
