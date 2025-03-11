-- +goose Up
-- +goose StatementBegin
CREATE TYPE email_status AS ENUM(
    'queued',
    'sent',
    'delivered',
    'opened',
    'clicked',
    'soft_bounced',
    'hard_bounced',
    'complained',
    'unsubscribed',
    'failed',
    'deferred'
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_types(
    id bigserial PRIMARY KEY,
    name varchar(50) UNIQUE NOT NULL
);

INSERT INTO email_types(name)
    VALUES ('campaign'),
('transactional');

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_campaigns(
    id public.xid PRIMARY KEY DEFAULT xid(),
    account_id bigint NOT NULL,
    name varchar(255) NOT NULL,
    subject varchar(255) NOT NULL,
    email_type_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (email_type_id) REFERENCES email_types(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_templates(
    id public.xid PRIMARY KEY DEFAULT xid(),
    account_id bigint NOT NULL,
    name varchar(255) NOT NULL,
    subject varchar(255) NOT NULL,
    email_type_id bigint NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (email_type_id) REFERENCES email_types(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_recipients(
    id public.xid PRIMARY KEY DEFAULT xid(),
    account_id bigint NOT NULL,
    email varchar(255) NOT NULL,
    name varchar(255),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

-- Create a non-unique index on the email column for better query performance
CREATE INDEX idx_email_recipients_email ON email_recipients(email);

-- Create a composite index on account_id and email columns
CREATE INDEX idx_email_recipients_account_id_email ON email_recipients(account_id, email);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_sends(
    id public.xid PRIMARY KEY DEFAULT xid(),
    account_id bigint NOT NULL,
    campaign_id public.xid,
    template_id public.xid,
    recipient_id public.xid NOT NULL,
    email_type_id bigint NOT NULL,
    current_status email_status NOT NULL DEFAULT 'queued',
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (campaign_id) REFERENCES email_campaigns(id) ON DELETE SET NULL,
    FOREIGN KEY (template_id) REFERENCES email_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (recipient_id) REFERENCES email_recipients(id) ON DELETE CASCADE,
    FOREIGN KEY (email_type_id) REFERENCES email_types(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_status_history(
    id bigserial PRIMARY KEY,
    account_id bigint NOT NULL,
    email_send_id public.xid NOT NULL,
    status email_status NOT NULL,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    metadata jsonb,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (email_send_id) REFERENCES email_sends(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_links(
    id public.xid PRIMARY KEY DEFAULT xid(),
    email_send_id public.xid NOT NULL,
    original_url text NOT NULL,
    tracked_url text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (email_send_id) REFERENCES email_sends(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_clicks(
    id bigserial PRIMARY KEY,
    email_link_id public.xid NOT NULL,
    clicked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address inet,
    user_agent text,
    FOREIGN KEY (email_link_id) REFERENCES email_links(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_opens(
    id bigserial PRIMARY KEY,
    email_send_id public.xid NOT NULL,
    opened_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address inet,
    user_agent text,
    FOREIGN KEY (email_send_id) REFERENCES email_sends(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_metrics(
    date date NOT NULL,
    account_id bigint NOT NULL,
    campaign_id public.xid,
    template_id public.xid,
    email_type_id bigint NOT NULL,
    sent int DEFAULT 0,
    delivered int DEFAULT 0,
    opened int DEFAULT 0,
    clicked int DEFAULT 0,
    soft_bounced int DEFAULT 0,
    hard_bounced int DEFAULT 0,
    complained int DEFAULT 0,
    unsubscribed int DEFAULT 0,
    failed int DEFAULT 0,
    deferred int DEFAULT 0,
    PRIMARY KEY (date, account_id, campaign_id, template_id, email_type_id),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (campaign_id) REFERENCES email_campaigns(id) ON DELETE SET NULL,
    FOREIGN KEY (template_id) REFERENCES email_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (email_type_id) REFERENCES email_types(id) ON DELETE CASCADE
);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TABLE email_unsubscribes(
    id bigserial PRIMARY KEY,
    account_id bigint NOT NULL,
    recipient_id public.xid NOT NULL,
    email_send_id public.xid,
    unsubscribe_type varchar(20) NOT NULL, -- 'list' or 'campaign'
    reason text,
    unsubscribed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address inet,
    user_agent text,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES email_recipients(id) ON DELETE CASCADE,
    FOREIGN KEY (email_send_id) REFERENCES email_sends(id) ON DELETE SET NULL
);

-- Create an index on recipient_id for faster lookups
CREATE INDEX idx_email_unsubscribes_recipient_id ON email_unsubscribes(recipient_id);

-- Create a composite index on account_id and unsubscribed_at for efficient querying
CREATE INDEX idx_email_unsubscribes_account_unsubscribed ON email_unsubscribes(account_id, unsubscribed_at);

-- +goose StatementEnd
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION update_email_metrics()
    RETURNS TRIGGER
    AS $$
DECLARE
    v_account_id bigint;
    v_campaign_id public.xid;
    v_template_id public.xid;
    v_email_type_id bigint;
BEGIN
    SELECT
        account_id,
        campaign_id,
        template_id,
        email_type_id INTO v_account_id,
        v_campaign_id,
        v_template_id,
        v_email_type_id
    FROM
        email_sends
    WHERE
        id = NEW.email_send_id;
    -- Update email_metrics
    INSERT INTO email_metrics(date, account_id, campaign_id, template_id, email_type_id, sent, delivered, opened, clicked, soft_bounced, hard_bounced, complained, unsubscribed, failed, DEFERRED)
        VALUES (CURRENT_DATE, v_account_id, v_campaign_id, v_template_id, v_email_type_id, CASE WHEN NEW.status = 'sent' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'delivered' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'opened' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'clicked' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'soft_bounced' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'hard_bounced' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'complained' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'unsubscribed' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'failed' THEN
                1
            ELSE
                0
            END, CASE WHEN NEW.status = 'deferred' THEN
                1
            ELSE
                0
            END)
    ON CONFLICT (date, account_id, campaign_id, template_id, email_type_id)
        DO UPDATE SET
            sent = email_metrics.sent + CASE WHEN NEW.status = 'sent' THEN
                1
            ELSE
                0
            END, delivered = email_metrics.delivered + CASE WHEN NEW.status = 'delivered' THEN
                1
            ELSE
                0
            END, opened = email_metrics.opened + CASE WHEN NEW.status = 'opened' THEN
                1
            ELSE
                0
            END, clicked = email_metrics.clicked + CASE WHEN NEW.status = 'clicked' THEN
                1
            ELSE
                0
            END, soft_bounced = email_metrics.soft_bounced + CASE WHEN NEW.status = 'soft_bounced' THEN
                1
            ELSE
                0
            END, hard_bounced = email_metrics.hard_bounced + CASE WHEN NEW.status = 'hard_bounced' THEN
                1
            ELSE
                0
            END, complained = email_metrics.complained + CASE WHEN NEW.status = 'complained' THEN
                1
            ELSE
                0
            END, unsubscribed = email_metrics.unsubscribed + CASE WHEN NEW.status = 'unsubscribed' THEN
                1
            ELSE
                0
            END, failed = email_metrics.failed + CASE WHEN NEW.status = 'failed' THEN
                1
            ELSE
                0
            END, DEFERRED = email_metrics.deferred + CASE WHEN NEW.status = 'deferred' THEN
                1
            ELSE
                0
            END;
    -- If the status is 'opened', insert a record into email_opens
    IF NEW.status = 'opened' THEN
        INSERT INTO email_opens(email_send_id, opened_at, ip_address, user_agent)
            VALUES (NEW.email_send_id, NEW.changed_at,(NEW.metadata ->> 'ip_address')::inet, NEW.metadata ->> 'user_agent');
    END IF;
    -- If the status is 'clicked', insert a record into email_clicks
    IF NEW.status = 'clicked' THEN
        INSERT INTO email_clicks(email_link_id, clicked_at, ip_address, user_agent)
            VALUES ((NEW.metadata ->> 'email_link_id')::public.xid, NEW.changed_at,(NEW.metadata ->> 'ip_address')::inet, NEW.metadata ->> 'user_agent');
    END IF;
    -- If the status is 'unsubscribed', insert a record into email_unsubscribes and update email_recipients
    IF NEW.status = 'unsubscribed' THEN
        INSERT INTO email_unsubscribes(account_id, recipient_id, email_send_id, unsubscribe_type, unsubscribed_at, ip_address, user_agent)
        SELECT
            v_account_id,
            recipient_id,
            NEW.email_send_id,
            'campaign',
            NEW.changed_at,
(NEW.metadata ->> 'ip_address')::inet,
            NEW.metadata ->> 'user_agent'
        FROM
            email_sends
        WHERE
            id = NEW.email_send_id;
        UPDATE
            email_recipients
        SET
            is_unsubscribed = TRUE,
            unsubscribe_date = NEW.changed_at
        WHERE
            id =(
                SELECT
                    recipient_id
                FROM
                    email_sends
                WHERE
                    id = NEW.email_send_id);
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- +goose StatementEnd
-- +goose StatementBegin
CREATE TRIGGER trigger_update_email_metrics
    AFTER INSERT ON email_status_history
    FOR EACH ROW
    EXECUTE FUNCTION update_email_metrics();

-- +goose StatementEnd
-- +goose Down
-- +goose StatementBegin
-- Drop triggers and functions first
DROP TRIGGER IF EXISTS trigger_update_email_metrics ON email_status_history CASCADE;

DROP TRIGGER IF EXISTS trigger_update_email_metrics ON email_status_history CASCADE;

DROP FUNCTION IF EXISTS update_email_metrics() CASCADE;

DROP FUNCTION IF EXISTS update_email_metrics() CASCADE;

-- Drop tables with CASCADE
DROP TABLE IF EXISTS email_metrics CASCADE;

DROP TABLE IF EXISTS email_opens CASCADE;

DROP TABLE IF EXISTS email_clicks CASCADE;

DROP TABLE IF EXISTS email_links CASCADE;

DROP TABLE IF EXISTS email_status_history CASCADE;

DROP TABLE IF EXISTS email_sends CASCADE;

DROP TABLE IF EXISTS email_recipients CASCADE;

DROP TABLE IF EXISTS email_templates CASCADE;

DROP TABLE IF EXISTS email_campaigns CASCADE;

DROP TABLE IF EXISTS email_types CASCADE;

DROP TABLE IF EXISTS email_unsubscribes CASCADE;

-- Drop the enum type
DROP TYPE IF EXISTS email_status CASCADE;

-- +goose StatementEnd
