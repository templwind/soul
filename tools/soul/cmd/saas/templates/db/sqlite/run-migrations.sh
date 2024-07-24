#!/bin/sh

set -e
set -x

DB_FILE=${DB_FILE:-/data/{{.dsnName}}.db}
MIGRATION_STATUS_FILE="/data/migrations_done"

# Create the SQLite database file if it doesn't exist
if [ ! -f "$DB_FILE" ]; then
    echo "Creating SQLite database file at $DB_FILE"
    sqlite3 $DB_FILE "VACUUM;"
else
    echo "SQLite database file already exists at $DB_FILE"
fi

# Enable Write-Ahead Logging (WAL) mode
echo "Enabling WAL mode for SQLite database at $DB_FILE"
sqlite3 $DB_FILE "PRAGMA journal_mode=WAL;"

# Run migration scripts
echo "Executing migrations for SQLite database at $DB_FILE"
/bin/goose -v -dir /migrations sqlite3 $DB_FILE up

# Indicate successful migration
touch $MIGRATION_STATUS_FILE

echo "Migrations completed."
