-- +goose Up
-- +goose StatementBegin
CREATE TABLE accounts(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
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
    primary_user_id bigint NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_accounts_genid
    BEFORE INSERT ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS user_types(
    id bigserial PRIMARY KEY,
    public_id text UNIQUE, -- Assuming PUBLIC_ID is a text type
    type_name text NOT NULL,
    description text NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
-- Insert default user types
INSERT INTO user_types(id, public_id, type_name, description)
    VALUES (1, 'superAdmin', 'Super Admin', 'Super administrator with full access'),
(2, 'companyUser', 'Company User', 'User with company-level access'),
(3, 'masterUser', 'Master User', 'Master user with elevated privileges'),
(4, 'serviceUser', 'Service User', 'Service user with basic access')
ON CONFLICT (id)
    DO NOTHING;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_user_types_genid
    BEFORE INSERT ON user_types
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE users(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
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
CREATE TRIGGER trigger_users_genid
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE user_accounts(
    user_id bigint NOT NULL,
    account_id bigint NOT NULL,
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
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    name text NOT NULL,
    description text,
    price DECIMAL NOT NULL,
    is_subscription boolean DEFAULT FALSE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_products_genid
    BEFORE INSERT ON products
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE subscriptions(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    product_id bigint NOT NULL,
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
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_subscriptions_product_id ON subscriptions(product_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE payment_methods(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    type TEXT NOT NULL, -- e.g., 'Visa', 'Mastercard'
    details text NOT NULL, -- e.g., 'Visa •••• 1867'
    is_primary boolean DEFAULT FALSE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE invoices(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    subscription_id bigint,
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
CREATE INDEX idx_invoices_user_id ON invoices(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE payment_attempts(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    invoice_id bigint NOT NULL,
    amount DECIMAL NOT NULL,
    status text NOT NULL,
    gateway_response text,
    attempt_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_payment_attempts_invoice_id ON payment_attempts(invoice_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE oauth_states(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    provider text NOT NULL,
    user_id bigint,
    user_role_id bigint REFERENCES user_types(id) DEFAULT 2,
    data jsonb NOT NULL DEFAULT '{}',
    used boolean DEFAULT FALSE,
    jwt_generated boolean DEFAULT FALSE,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp DEFAULT CURRENT_TIMESTAMP
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_oauth_states_genid
    BEFORE INSERT ON oauth_states
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE posts(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE comments(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    post_id bigint NOT NULL,
    user_id bigint NOT NULL,
    content text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_comments_post_id ON comments(post_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_comments_user_id ON comments(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE tags(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    tag text NOT NULL,
    post_id bigint, -- linkage to a blog post
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE SET NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_tags_post_id ON tags(post_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE reviews(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    product_id bigint NOT NULL,
    user_id bigint NOT NULL,
    rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
    content text,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_reviews_product_id ON reviews(product_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_reviews_user_id ON reviews(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE audit_logs(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    action text NOT NULL,
    entity text NOT NULL,
    entity_id bigint NOT NULL,
    details text,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE roles(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    name text NOT NULL,
    description text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_roles_genid
    BEFORE INSERT ON roles
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE permissions(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    name text NOT NULL,
    description text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_permissions_genid
    BEFORE INSERT ON permissions
    FOR EACH ROW
    EXECUTE FUNCTION generate_public_id();

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE role_permissions(
    role_id bigint NOT NULL,
    permission_id bigint NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE user_roles(
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE notifications(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    message text NOT NULL,
    read boolean DEFAULT FALSE NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_notifications_user_id ON notifications(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE settings(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint,
    key TEXT NOT NULL,
    value text NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE INDEX idx_settings_user_id ON settings(user_id);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE attachments(
    id bigserial PRIMARY KEY,
    public_id PUBLIC_ID UNIQUE,
    user_id bigint NOT NULL,
    file_name text NOT NULL,
    file_url text NOT NULL,
    file_size integer NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
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
