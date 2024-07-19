package db

// DBConfig defines the options for PersistentSQLx
type DBConfig struct {
	DSN           string
	EnableWALMode bool
}
