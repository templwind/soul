-- +goose Up
-- +goose StatementBegin
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- +goose StatementEnd
-- +goose StatementBegin
-- Function to update updated_at timestamp on row update
CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- +goose StatementEnd
-- +goose StatementBegin
-- Function to set both created_at and updated_at on row insert
CREATE OR REPLACE FUNCTION set_timestamp_columns()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.created_at = CURRENT_TIMESTAMP;
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- +goose StatementEnd
-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION IF EXISTS set_timestamp_columns();

-- +goose StatementEnd
