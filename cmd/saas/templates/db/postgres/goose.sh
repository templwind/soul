#!/bin/bash

usage() {
  echo "Usage: . ./goose.sh [env_file]"
  echo "Sets environment variables from env_file."
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  usage
  exit 0
fi

if [ -z "$1" ]; then
  echo "Error: env_file not provided."
  usage
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: env_file not found."
  usage
  exit 1
fi

# source the env file to make variables available
source "$1"

export GOOSE_DBSTRING="user=$POSTGRES_USER password=$POSTGRES_PASSWORD host=$EXTERNAL_PGHOST port=$POSTGRES_EXTERNAL_PORT dbname=$POSTGRES_DB sslmode=disable"
export GOOSE_DRIVER=postgres

echo $GOOSE_DBSTRING

echo "Loaded goose environment variables from $1."
