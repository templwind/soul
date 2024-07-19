-- +goose Up
-- +goose StatementBegin
PRAGMA foreign_keys = ON;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE
    IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY DEFAULT ('r' || lower(hex (randomblob (7)))) NOT NULL,
        company_name TEXT,
        address_1 TEXT,
        address_2 TEXT,
        city TEXT,
        state_province TEXT,
        postal_code TEXT,
        country TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        primary_user_id TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL
    );

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE
    IF NOT EXISTS user_types (
        id TEXT PRIMARY KEY NOT NULL,
        type_name TEXT NOT NULL,
        description TEXT NOT NULL
    );

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE
    IF NOT EXISTS users (
        id TEXT PRIMARY KEY DEFAULT ('r' || lower(hex (randomblob (7)))) NOT NULL,
        name TEXT DEFAULT '' NOT NULL,
        username TEXT NOT NULL,
        email TEXT DEFAULT '' NOT NULL UNIQUE,
        email_visibility BOOLEAN DEFAULT FALSE NOT NULL,
        last_reset_sent_at TEXT DEFAULT '' NOT NULL,
        last_verification_sent_at TEXT DEFAULT '' NOT NULL,
        password_hash TEXT NOT NULL,
        token_key TEXT NOT NULL,
        verified BOOLEAN DEFAULT FALSE NOT NULL,
        avatar TEXT DEFAULT '' NOT NULL,
        type_id TEXT DEFAULT 'USER_TYPE_ADMIN' NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        FOREIGN KEY (type_id) REFERENCES user_types (id) ON DELETE SET NULL
    );

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE
    IF NOT EXISTS user_accounts (
        user_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        PRIMARY KEY (user_id, account_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
    );

CREATE INDEX idx_user_accounts_user_id ON user_accounts (user_id);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS user_accounts;

DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS user_types;

DROP TABLE IF EXISTS accounts;

-- +goose StatementEnd