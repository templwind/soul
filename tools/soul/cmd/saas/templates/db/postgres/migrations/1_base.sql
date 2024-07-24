-- +goose Up
-- +goose StatementBegin
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- +goose StatementEnd
-- +goose StatementBegin
DO $$
BEGIN
    CREATE DOMAIN PUBLIC_ID AS varchar(11);
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END
$$;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION new_public_id()
    RETURNS varchar (
        11
)
    AS $$
DECLARE
    gkey text;
    key varchar(11);
BEGIN
    LOOP
        -- Generate a UUID and convert it to text
        gkey := encode(gen_random_bytes(16), 'base64');
        -- Remove any non-alphanumeric characters
        gkey := regexp_replace(gkey, '[^a-zA-Z0-9]', '', 'g');
        key := substr(gkey, 1, 11);
        -- Ensure the length is exactly 11 characters
        IF length(key) = 11 THEN
            RETURN key;
        END IF;
    END LOOP;
END
$$
LANGUAGE plpgsql;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION generate_public_id()
    RETURNS TRIGGER
    AS $$
DECLARE
    key PUBLIC_ID;
    found text;
BEGIN
    IF NEW.public_id IS NOT NULL THEN
        key := NEW.public_id;
        IF length(key) <> 11 THEN
            RAISE 'User defined key value % has invalid length. Expected 11, got %.', key, length(key);
        END IF;
    ELSE
        LOOP
            key := new_public_id();
            EXECUTE 'SELECT 1 FROM ' || quote_ident(TG_TABLE_NAME) || ' WHERE public_id = ' || quote_literal(key) INTO found;
            IF found IS NULL THEN
                EXIT;
            END IF;
        END LOOP;
    END IF;
    NEW.public_id = key;
    RETURN NEW;
END
$$
LANGUAGE plpgsql;

-- +goose StatementEnd
-- +goose StatementBegin
DO $$
BEGIN
    CREATE DOMAIN TRANSCRIPTION AS jsonb;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END
$$;

-- +goose StatementEnd
-- +goose Down
-- +goose StatementBegin
DROP FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
DROP FUNCTION new_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
DROP DOMAIN PUBLIC_ID;

-- +goose StatementEnd
-- +goose StatementBegin
DROP DOMAIN TRANSCRIPTION;

-- +goose StatementEnd
