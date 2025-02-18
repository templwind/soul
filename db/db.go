package db

import (
	"context"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/xo/dburl"
	"github.com/zeromicro/go-zero/core/logx"
)

// PersistentSQLx contains the persistent database connection
type PersistentSQLx struct {
	db    *sqlx.DB
	dsn   string
	opts  *DBConfig
	debug bool
}

// OptFunc defines the signature for an option function
type OptFunc[T any] func(*T)

// Connect creates a new PersistentSQLx instance
func MustConnect(opts ...OptFunc[DBConfig]) *PersistentSQLx {
	options := WithOptions(defaultOptions, opts...)
	return NewWithOptions(options)
}

// NewWithOptions creates a new PersistentSQLx instance with the given options
func NewWithOptions(opts *DBConfig) *PersistentSQLx {
	dsn := strings.ReplaceAll(opts.DSN, "\"", "")
	db, err := connect(opts)
	if err != nil {
		panic("Failed to connect to database: " + err.Error())
	}

	psqlx := &PersistentSQLx{
		db:    db,
		dsn:   dsn,
		opts:  opts,
		debug: false,
	}

	// Start a go-routine to continuously check connection health
	go psqlx.ensureConnection()

	return psqlx
}

// WithOptions builds the options with the given opt
func WithOptions(defaultOpts func() *DBConfig, opts ...OptFunc[DBConfig]) *DBConfig {
	p := defaultOpts()
	for _, opt := range opts {
		opt(p)
	}
	return p
}

// defaultOptions returns the default options for PersistentSQLx
func defaultOptions() *DBConfig {
	return &DBConfig{
		EnableWALMode: false,
	}
}

// WithDSN sets the DSN
func WithDSN(dsn string) OptFunc[DBConfig] {
	return func(p *DBConfig) {
		p.DSN = dsn
	}
}

// WithEnableWALMode sets the WAL mode
func WithEnableWALMode(enable bool) OptFunc[DBConfig] {
	return func(p *DBConfig) {
		p.EnableWALMode = enable
	}
}

// SetDebug enables or disables debug logging
func (psqlx *PersistentSQLx) SetDebug(enabled bool) {
	psqlx.debug = enabled
}

// debugLog logs messages only when debug mode is enabled
func (psqlx *PersistentSQLx) debugLog(msg string, fields ...logx.LogField) {
	if psqlx.debug {
		logx.WithContext(context.Background()).Infow(msg, fields...)
	}
}

// connect establishes a new database connection
func connect(opts *DBConfig) (*sqlx.DB, error) {
	u, err := dburl.Parse(opts.DSN)
	if err != nil {
		logx.Error("Failed to parse DSN", logx.Field("error", err))
		return nil, err
	}

	// Handle SQLite3 specific logic
	if u.Driver == "sqlite3" {
		dbPath := u.DSN
		if dbPath[0] == '/' {
			dbPath = dbPath[1:]
		}
		if err := ensureSQLiteFile(dbPath); err != nil {
			return nil, err
		}
	}

	// Use sqlx.Connect with the parsed driver and DSN
	dbConn, err := sqlx.Connect(u.Driver, u.DSN)
	if err != nil {
		return nil, err
	}

	// Enable WAL mode if SQLite and requested
	if u.Driver == "sqlite3" && opts.EnableWALMode {
		_, err = dbConn.Exec("PRAGMA journal_mode = WAL;")
		if err != nil {
			return nil, err
		}
	}

	return dbConn, nil
}

// ensureSQLiteFile ensures that the SQLite database file and its directory exist
func ensureSQLiteFile(dbPath string) error {
	dir := filepath.Dir(dbPath)
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, os.ModePerm); err != nil {
			return fmt.Errorf("failed to create directory %s: %v", dir, err)
		}
	}

	file, err := os.OpenFile(dbPath, os.O_RDWR|os.O_CREATE, 0666)
	if err != nil {
		return fmt.Errorf("failed to create or open database file %s: %v", dbPath, err)
	}
	file.Close()
	return nil
}

// GetDB returns the database connection
func (psqlx *PersistentSQLx) GetDB() *sqlx.DB {
	return psqlx.db
}

// reconnect attempts to re-establish the database connection with exponential backoff
func (psqlx *PersistentSQLx) reconnect() error {
	const maxBackoff = 5 * time.Minute
	baseDelay := 500 * time.Millisecond

	for attempts := 0; ; attempts++ {
		psqlx.debugLog("Attempting to reconnect", logx.Field("attempt", attempts))

		db, err := connect(psqlx.opts)
		if err == nil {
			psqlx.db = db
			psqlx.debugLog("Successfully reconnected to database")
			return nil
		}

		if attempts > 0 {
			backoff := time.Duration(math.Pow(2, float64(attempts))) * baseDelay
			if backoff > maxBackoff {
				backoff = maxBackoff
			}
			psqlx.debugLog("Reconnection failed, waiting before retry",
				logx.Field("backoff", backoff),
				logx.Field("error", err))
			time.Sleep(backoff)
		}
	}
}

// ensureConnection continuously checks the health of the database connection
func (psqlx *PersistentSQLx) ensureConnection() {
	for {
		if err := psqlx.db.Ping(); err != nil {
			psqlx.debugLog("Ping failed, attempting reconnect", logx.Field("error", err))
			psqlx.reconnect()
		}
		time.Sleep(1 * time.Minute)
	}
}
