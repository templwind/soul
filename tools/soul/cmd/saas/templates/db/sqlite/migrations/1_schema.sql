-- +goose Up
-- +goose StatementBegin
PRAGMA foreign_keys = ON;

PRAGMA journal_mode = WAL;

-- +goose StatementEnd
-- Accounts Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS accounts(
    id text PRIMARY KEY DEFAULT ('a' || lower(hex(randomblob(7)))) NOT NULL,
    company_name text,
    address_1 text,
    address_2 text,
    city text,
    state_province text,
    postal_code text,
    country text,
    phone text,
    email text,
    website text,
    primary_user_id text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- User Types Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS user_types(
    id text PRIMARY KEY NOT NULL,
    type_name text NOT NULL,
    description text NOT NULL
);

-- +goose StatementEnd
-- Users Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS users(
    id text PRIMARY KEY DEFAULT ('u' || lower(hex(randomblob(7)))) NOT NULL,
    name text DEFAULT '' NOT NULL,
    username text NOT NULL,
    email text DEFAULT '' NOT NULL UNIQUE,
    email_visibility boolean DEFAULT FALSE NOT NULL,
    last_reset_sent_at text DEFAULT '' NOT NULL,
    last_verification_sent_at text DEFAULT '' NOT NULL,
    password_hash text NOT NULL,
    token_key text NOT NULL,
    verified boolean DEFAULT FALSE NOT NULL,
    avatar text DEFAULT '' NOT NULL,
    type_id text DEFAULT 'USER_TYPE_ADMIN' NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (type_id) REFERENCES user_types(id) ON DELETE SET NULL
);

-- +goose StatementEnd
-- User Accounts Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS user_accounts(
    user_id text NOT NULL,
    account_id text NOT NULL,
    PRIMARY KEY (user_id, account_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_accounts_user_id ON user_accounts(user_id);

-- +goose StatementEnd
-- Products Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS products(
    id text PRIMARY KEY DEFAULT ('p' || lower(hex(randomblob(7)))) NOT NULL,
    name text NOT NULL,
    description text,
    price real NOT NULL,
    is_subscription boolean DEFAULT FALSE NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- Subscriptions Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS subscriptions(
    id text PRIMARY KEY DEFAULT ('s' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    product_id text NOT NULL,
    start_date text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_date text,
    status text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);

CREATE INDEX idx_subscriptions_product_id ON subscriptions(product_id);

-- +goose StatementEnd
-- Payment Methods Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS payment_methods(
    id text PRIMARY KEY DEFAULT ('m' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    type text NOT NULL, -- e.g., 'Visa', 'Mastercard'
    details text NOT NULL, -- e.g., 'Visa •••• 1867'
    is_primary boolean DEFAULT FALSE NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);

-- +goose StatementEnd
-- Invoices Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS invoices(
    id text PRIMARY KEY DEFAULT ('i' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    subscription_id text,
    amount real NOT NULL,
    status text NOT NULL,
    invoice_date text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    due_date text,
    paid_date text,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL
);

CREATE INDEX idx_invoices_user_id ON invoices(user_id);

CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);

-- +goose StatementEnd
-- Payment Attempts Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS payment_attempts(
    id text PRIMARY KEY DEFAULT ('a' || lower(hex(randomblob(7)))) NOT NULL,
    invoice_id text NOT NULL,
    amount real NOT NULL,
    status text NOT NULL,
    gateway_response text,
    attempt_date text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

CREATE INDEX idx_payment_attempts_invoice_id ON payment_attempts(invoice_id);

-- +goose StatementEnd
-- OAuth States Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS oauth_states(
    id text PRIMARY KEY DEFAULT ('o' || lower(hex(randomblob(7)))) NOT NULL,
    provider text NOT NULL,
    user_id text,
    user_role_id text REFERENCES user_types(id) DEFAULT 'USER_TYPE_USER',
    data text NOT NULL DEFAULT '{}',
    used boolean DEFAULT FALSE,
    jwt_generated boolean DEFAULT FALSE,
    created_at text DEFAULT CURRENT_TIMESTAMP,
    expires_at text DEFAULT CURRENT_TIMESTAMP
);

-- +goose StatementEnd
-- Posts Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS posts(
    id text PRIMARY KEY DEFAULT ('p' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_posts_user_id ON posts(user_id);

-- +goose StatementEnd
-- Comments Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS comments(
    id text PRIMARY KEY DEFAULT ('c' || lower(hex(randomblob(7)))) NOT NULL,
    post_id text NOT NULL,
    user_id text NOT NULL,
    content text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_comments_post_id ON comments(post_id);

CREATE INDEX idx_comments_user_id ON comments(user_id);

-- +goose StatementEnd
-- Tags Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS tags(
    id text PRIMARY KEY DEFAULT ('t' || lower(hex(randomblob(7)))) NOT NULL,
    tag text NOT NULL,
    post_id text, -- linkage to a blog post
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE SET NULL
);

CREATE INDEX idx_tags_post_id ON tags(post_id);

-- +goose StatementEnd
-- Reviews Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS reviews(
    id text PRIMARY KEY DEFAULT ('r' || lower(hex(randomblob(7)))) NOT NULL,
    product_id text NOT NULL,
    user_id text NOT NULL,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    content text,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_reviews_product_id ON reviews(product_id);

CREATE INDEX idx_reviews_user_id ON reviews(user_id);

-- +goose StatementEnd
-- Audit Logs Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS audit_logs(
    id text PRIMARY KEY DEFAULT ('a' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    action text NOT NULL,
    entity text NOT NULL,
    entity_id text NOT NULL,
    details text,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);

-- +goose StatementEnd
-- Roles Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS roles(
    id text PRIMARY KEY DEFAULT ('r' || lower(hex(randomblob(7)))) NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- Permissions Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS permissions(
    id text PRIMARY KEY DEFAULT ('p' || lower(hex(randomblob(7)))) NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- Role Permissions Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS role_permissions(
    role_id text NOT NULL,
    permission_id text NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);

CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- +goose StatementEnd
-- User Roles Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS user_roles(
    user_id text NOT NULL,
    role_id text NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

-- +goose StatementEnd
-- Notifications Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS notifications(
    id text PRIMARY KEY DEFAULT ('n' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    message text NOT NULL,
    read boolean DEFAULT FALSE NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);

-- +goose StatementEnd
-- Settings Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS settings(
    id text PRIMARY KEY DEFAULT ('s' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text,
    key text NOT NULL,
    value text NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_settings_user_id ON settings(user_id);

-- +goose StatementEnd
-- Attachments Table
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS attachments(
    id text PRIMARY KEY DEFAULT ('a' || lower(hex(randomblob(7)))) NOT NULL,
    user_id text NOT NULL,
    file_name text NOT NULL,
    file_url text NOT NULL,
    file_size integer NOT NULL,
    created_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at text DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_attachments_user_id ON attachments(user_id);

-- +goose StatementEnd
-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS attachments;

DROP TABLE IF EXISTS settings;

DROP TABLE IF EXISTS notifications;

DROP TABLE IF EXISTS user_roles;

DROP TABLE IF EXISTS role_permissions;

DROP TABLE IF EXISTS permissions;

DROP TABLE IF EXISTS roles;

DROP TABLE IF EXISTS audit_logs;

DROP TABLE IF EXISTS reviews;

DROP TABLE IF EXISTS tags;

DROP TABLE IF EXISTS comments;

DROP TABLE IF EXISTS posts;

DROP TABLE IF EXISTS oauth_states;

DROP TABLE IF EXISTS payment_attempts;

DROP TABLE IF EXISTS invoices;

DROP TABLE IF EXISTS payment_methods;

DROP TABLE IF EXISTS subscriptions;

DROP TABLE IF EXISTS products;

DROP TABLE IF EXISTS user_accounts;

DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS user_types;

DROP TABLE IF EXISTS accounts;

-- +goose StatementEnd
