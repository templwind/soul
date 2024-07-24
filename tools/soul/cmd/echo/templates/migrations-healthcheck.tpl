#!/bin/sh

# Check if the migration status file exists
if [ -f "/data/migrations_done" ]; then
    exit 0
else
    exit 1
fi
