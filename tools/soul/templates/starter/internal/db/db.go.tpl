package db

import (
	"math"
	"strings"
	"time"

	"{{ .ModuleName }}/internal/config"

	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
)

type PersistentSQLx struct {
	db  *sqlx.DB
	dsn string
}

func NewPersistentSQLx(dsn string, c *config.Config) (*PersistentSQLx, error) {
	dsn = strings.ReplaceAll(dsn, "\"", "")
	db, err := connect(dsn)
	if err != nil {
		return nil, err
	}

	// Run migrations as required
	if c.RunMigrations {
		mustRunMigrations(db, c)
	}

	psqlx := &PersistentSQLx{
		db:  db,
		dsn: dsn,
	}

	// Start a go-routine to continuously check connection health
	go psqlx.ensureConnection()

	return psqlx, nil
}

func (psqlx *PersistentSQLx) GetDB() *sqlx.DB {
	return psqlx.db
}

func (psqlx *PersistentSQLx) reconnect() error {
	// Exponential backoff parameters
	const maxBackoff = 5 * time.Minute
	baseDelay := 500 * time.Millisecond

	for attempts := 0; ; attempts++ {
		db, err := connect(psqlx.dsn)
		if err == nil {
			psqlx.db = db
			return nil
		}

		if attempts > 0 {
			// Exponential backoff calculation
			backoff := time.Duration(math.Pow(2, float64(attempts))) * baseDelay
			if backoff > maxBackoff {
				backoff = maxBackoff
			}

			time.Sleep(backoff)
		}
	}
}

func (psqlx *PersistentSQLx) ensureConnection() {
	for {
		// Implement a simple ping check
		if err := psqlx.db.Ping(); err != nil {
			// If ping fails, try to reconnect
			psqlx.reconnect()
		}

		// Sleep for some time before the next health check
		time.Sleep(1 * time.Minute)
	}
}
