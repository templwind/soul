#!/bin/sh
# wait-for-postgres.sh

set -e
set -x

cmd="$@"

export POSTGRES_SSL_MODE=${POSTGRES_SSL_MODE:-disable} # Default to 'disable' if not set

# Print environment variables for debugging
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_PASSWORD: $POSTGRES_PASSWORD"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_HOST: $POSTGRES_HOST"
echo "POSTGRES_PORT: $POSTGRES_PORT"
echo "POSTGRES_SSL_MODE: $POSTGRES_SSL_MODE"

# Wait for PostgreSQL server to be ready
until pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER"; do
  echo >&2 "Postgres is unavailable - sleeping"
  sleep 1
done

echo >&2 "Postgres is up - executing command"
exec $cmd
