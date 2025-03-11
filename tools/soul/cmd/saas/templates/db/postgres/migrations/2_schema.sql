-- +goose Up
-- +goose StatementBegin
CREATE TABLE accounts(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    primary_user_id uuid NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for accounts table
CREATE TRIGGER set_timestamp_accounts
    BEFORE INSERT ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_accounts
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS user_types(
    id bigserial PRIMARY KEY,
    type_name text NOT NULL,
    description text NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Insert default user types
INSERT INTO user_types(id, type_name, description)
    VALUES (1, 'Super Admin', 'Super administrator with full access'),
(2, 'Company User', 'User with company-level access'),
(3, 'Master User', 'Master user with elevated privileges'),
(4, 'Service User', 'Service user with basic access')
ON CONFLICT (id)
    DO NOTHING;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE users(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name text DEFAULT '' NOT NULL,
    last_name text DEFAULT '' NOT NULL,
    title text DEFAULT '' NOT NULL,
    username text NOT NULL,
    email text DEFAULT '' NOT NULL UNIQUE,
    email_visibility boolean DEFAULT FALSE NOT NULL,
    last_reset_sent_at timestamp DEFAULT CURRENT_TIMESTAMP,
    last_verification_sent_at timestamp DEFAULT CURRENT_TIMESTAMP,
    password_hash text NOT NULL,
    token_key text NOT NULL,
    verified boolean DEFAULT FALSE NOT NULL,
    avatar text DEFAULT '' NOT NULL,
    type_id bigint DEFAULT 1 NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (type_id) REFERENCES user_types(id) ON DELETE SET NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for users table
CREATE TRIGGER set_timestamp_users
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_users
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
-- Add foreign key constraint for accounts.primary_user_id after users table is created
ALTER TABLE accounts
    ADD CONSTRAINT fk_accounts_primary_user FOREIGN KEY (primary_user_id) REFERENCES users(id) ON DELETE RESTRICT;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE user_accounts(
    user_id uuid NOT NULL,
    account_id uuid NOT NULL,
    PRIMARY KEY (user_id, account_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_user_accounts_user_id ON user_accounts(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE products(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    description text,
    price DECIMAL NOT NULL,
    is_subscription boolean DEFAULT FALSE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for products table
CREATE TRIGGER set_timestamp_products
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_products
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE subscriptions(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    product_id uuid NOT NULL,
    start_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_date timestamp,
    status text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for subscriptions table
CREATE TRIGGER set_timestamp_subscriptions
    BEFORE INSERT ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_subscriptions
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_subscriptions_product_id ON subscriptions(product_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE invoices(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL,
    subscription_id uuid,
    amount DECIMAL NOT NULL,
    status text NOT NULL,
    invoice_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    due_date timestamp,
    paid_date timestamp,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE SET NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for invoices table
CREATE TRIGGER set_timestamp_invoices
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_invoices
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_invoices_user_id ON invoices(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE oauth_states(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider text NOT NULL,
    user_id uuid,
    user_role_id bigint REFERENCES user_types(id) DEFAULT 2,
    data jsonb NOT NULL DEFAULT '{}',
    used boolean DEFAULT FALSE,
    jwt_generated boolean DEFAULT FALSE,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for oauth_states table
CREATE TRIGGER set_timestamp_oauth_states
    BEFORE INSERT ON oauth_states
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE settings(
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid,
    key TEXT NOT NULL,
    value text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Trigger to update timestamps for settings table
CREATE TRIGGER set_timestamp_settings
    BEFORE INSERT ON settings
    FOR EACH ROW
    EXECUTE FUNCTION set_timestamp_columns();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER update_timestamp_settings
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_settings_user_id ON settings(user_id);

-- +goose StatementEnd
-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS settings;

DROP TABLE IF EXISTS oauth_states;

DROP TABLE IF EXISTS invoices;

DROP TABLE IF EXISTS subscriptions;

DROP TABLE IF EXISTS products;

DROP TABLE IF EXISTS user_accounts;

DROP TABLE IF EXISTS users;

DROP TABLE IF EXISTS user_types;

DROP TABLE IF EXISTS accounts;

-- +goose StatementEnd
