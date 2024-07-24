#!/bin/sh
# run-migrations.sh

export POSTGRES_SSL_MODE=${POSTGRES_SSL_MODE:-disable} # Default to 'disable' if not set

set -e
set -x

# Wait for the PostgreSQL server to be ready
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD="$POSTGRES_PASSWORD" pg_isready --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --timeout=5 --username="$POSTGRES_USER"; do
    sleep 1
done

echo "PostgreSQL is ready."

# Function to create database if it doesn't exist
create_database_if_not_exists() {
    local db_name=$1
    if [ "$(PGPASSWORD="$POSTGRES_PASSWORD" psql -tA -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres -c "SELECT 1 FROM pg_database WHERE datname='${db_name}'")" != '1' ]; then
        echo "Creating database ${db_name}..."
        PGPASSWORD="$POSTGRES_PASSWORD" psql -a -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres <<-EOSQL
        \set ON_ERROR_STOP on
        CREATE DATABASE "${db_name}" OWNER postgres;
        GRANT ALL PRIVILEGES ON DATABASE "${db_name}" TO "$POSTGRES_USER";
        \set ON_ERROR_STOP off
EOSQL
    else
        echo "Database ${db_name} already exists."
    fi
}

# Create POSTGRES_DB database if it doesn't exist
create_database_if_not_exists "$POSTGRES_DB"

echo "Database is ready."

# Create extension if not exists
create_extension_if_not_exists() {
    local db_name=$1
    echo "Creating extension pgcrypto in database ${db_name}..."
    PGPASSWORD="$POSTGRES_PASSWORD" psql -a -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $db_name <<-EOSQL
    \set ON_ERROR_STOP on
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    \set ON_ERROR_STOP off
EOSQL
}

# Ensure the pgcrypto extension is created
create_extension_if_not_exists "$POSTGRES_DB"

echo "Extensions created."

# Run migration scripts
echo "Executing migrations for $POSTGRES_DB"
PGPASSWORD="$POSTGRES_PASSWORD" /bin/goose -v -dir /migrations postgres "user=$POSTGRES_USER password=$POSTGRES_PASSWORD dbname=$POSTGRES_DB sslmode=$POSTGRES_SSL_MODE host=$POSTGRES_HOST port=$POSTGRES_PORT connect_timeout=180" up

echo "Migrations completed."
