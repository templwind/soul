package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// EmailUnsubscribe represents a row from 'public.email_unsubscribes'.
type EmailUnsubscribe struct {
	ID              int64          `json:"id" db:"id" form:"id"`                                           // id
	AccountID       int64          `json:"account_id" db:"account_id" form:"account_id"`                   // account_id
	RecipientID     Xid            `json:"recipient_id" db:"recipient_id" form:"recipient_id"`             // recipient_id
	EmailSendID     NullXid        `json:"email_send_id" db:"email_send_id" form:"email_send_id"`          // email_send_id
	UnsubscribeType string         `json:"unsubscribe_type" db:"unsubscribe_type" form:"unsubscribe_type"` // unsubscribe_type
	Reason          sql.NullString `json:"reason" db:"reason" form:"reason"`                               // reason
	UnsubscribedAt  time.Time      `json:"unsubscribed_at" db:"unsubscribed_at" form:"unsubscribed_at"`    // unsubscribed_at
	IPAddress       sql.NullString `json:"ip_address" db:"ip_address" form:"ip_address"`                   // ip_address
	UserAgent       sql.NullString `json:"user_agent" db:"user_agent" form:"user_agent"`                   // user_agent
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailUnsubscribe] exists in the database.
func (eu *EmailUnsubscribe) Exists() bool {
	return eu._exists
}

// Deleted returns true when the [EmailUnsubscribe] has been marked for deletion
// from the database.
func (eu *EmailUnsubscribe) Deleted() bool {
	return eu._deleted
}

// Insert inserts the [EmailUnsubscribe] to the database.
func (eu *EmailUnsubscribe) Insert(ctx context.Context, db DB) error {
	switch {
	case eu._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case eu._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.email_unsubscribes (` +
		`account_id, recipient_id, email_send_id, unsubscribe_type, reason, unsubscribed_at, ip_address, user_agent` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8` +
		`) RETURNING id`
	// run
	logf(sqlstr, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent)
	if err := db.QueryRowContext(ctx, sqlstr, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent).Scan(&eu.ID); err != nil {
		return logerror(err)
	}
	// set exists
	eu._exists = true
	return nil
}

// Update updates a [EmailUnsubscribe] in the database.
func (eu *EmailUnsubscribe) Update(ctx context.Context, db DB) error {
	switch {
	case !eu._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case eu._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_unsubscribes SET ` +
		`account_id = $1, recipient_id = $2, email_send_id = $3, unsubscribe_type = $4, reason = $5, unsubscribed_at = $6, ip_address = $7, user_agent = $8 ` +
		`WHERE id = $9`
	// run
	logf(sqlstr, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent, eu.ID)
	if _, err := db.ExecContext(ctx, sqlstr, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent, eu.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailUnsubscribe] to the database.
func (eu *EmailUnsubscribe) Save(ctx context.Context, db DB) error {
	if eu.Exists() {
		return eu.Update(ctx, db)
	}
	return eu.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailUnsubscribe].
func (eu *EmailUnsubscribe) Upsert(ctx context.Context, db DB) error {
	switch {
	case eu._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_unsubscribes (` +
		`id, account_id, recipient_id, email_send_id, unsubscribe_type, reason, unsubscribed_at, ip_address, user_agent` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`account_id = EXCLUDED.account_id, recipient_id = EXCLUDED.recipient_id, email_send_id = EXCLUDED.email_send_id, unsubscribe_type = EXCLUDED.unsubscribe_type, reason = EXCLUDED.reason, unsubscribed_at = EXCLUDED.unsubscribed_at, ip_address = EXCLUDED.ip_address, user_agent = EXCLUDED.user_agent `
	// run
	logf(sqlstr, eu.ID, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent)
	if _, err := db.ExecContext(ctx, sqlstr, eu.ID, eu.AccountID, eu.RecipientID, eu.EmailSendID, eu.UnsubscribeType, eu.Reason, eu.UnsubscribedAt, eu.IPAddress, eu.UserAgent); err != nil {
		return logerror(err)
	}
	// set exists
	eu._exists = true
	return nil
}

// Delete deletes the [EmailUnsubscribe] from the database.
func (eu *EmailUnsubscribe) Delete(ctx context.Context, db DB) error {
	switch {
	case !eu._exists: // doesn't exist
		return nil
	case eu._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.email_unsubscribes ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, eu.ID)
	if _, err := db.ExecContext(ctx, sqlstr, eu.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	eu._deleted = true
	return nil
}

// EmailUnsubscribeByID retrieves a row from 'public.email_unsubscribes' as a [EmailUnsubscribe].
//
// Generated from index 'email_unsubscribes_pkey'.
func EmailUnsubscribeByID(ctx context.Context, db DB, id int64) (*EmailUnsubscribe, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, recipient_id, email_send_id, unsubscribe_type, reason, unsubscribed_at, ip_address, user_agent ` +
		`FROM public.email_unsubscribes ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	eu := EmailUnsubscribe{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&eu.ID, &eu.AccountID, &eu.RecipientID, &eu.EmailSendID, &eu.UnsubscribeType, &eu.Reason, &eu.UnsubscribedAt, &eu.IPAddress, &eu.UserAgent); err != nil {
		return nil, logerror(err)
	}
	return &eu, nil
}

// EmailUnsubscribesByAccountIDUnsubscribedAt retrieves a row from 'public.email_unsubscribes' as a [EmailUnsubscribe].
//
// Generated from index 'idx_email_unsubscribes_account_unsubscribed'.
func EmailUnsubscribesByAccountIDUnsubscribedAt(ctx context.Context, db DB, accountID int64, unsubscribedAt time.Time) ([]*EmailUnsubscribe, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, recipient_id, email_send_id, unsubscribe_type, reason, unsubscribed_at, ip_address, user_agent ` +
		`FROM public.email_unsubscribes ` +
		`WHERE account_id = $1 AND unsubscribed_at = $2`
	// run
	logf(sqlstr, accountID, unsubscribedAt)
	rows, err := db.QueryContext(ctx, sqlstr, accountID, unsubscribedAt)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*EmailUnsubscribe
	for rows.Next() {
		eu := EmailUnsubscribe{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&eu.ID, &eu.AccountID, &eu.RecipientID, &eu.EmailSendID, &eu.UnsubscribeType, &eu.Reason, &eu.UnsubscribedAt, &eu.IPAddress, &eu.UserAgent); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &eu)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// EmailUnsubscribesByRecipientID retrieves a row from 'public.email_unsubscribes' as a [EmailUnsubscribe].
//
// Generated from index 'idx_email_unsubscribes_recipient_id'.
func EmailUnsubscribesByRecipientID(ctx context.Context, db DB, recipientID Xid) ([]*EmailUnsubscribe, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, recipient_id, email_send_id, unsubscribe_type, reason, unsubscribed_at, ip_address, user_agent ` +
		`FROM public.email_unsubscribes ` +
		`WHERE recipient_id = $1`
	// run
	logf(sqlstr, recipientID)
	rows, err := db.QueryContext(ctx, sqlstr, recipientID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*EmailUnsubscribe
	for rows.Next() {
		eu := EmailUnsubscribe{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&eu.ID, &eu.AccountID, &eu.RecipientID, &eu.EmailSendID, &eu.UnsubscribeType, &eu.Reason, &eu.UnsubscribedAt, &eu.IPAddress, &eu.UserAgent); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &eu)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// AccountByAccountID returns the Account associated with the [EmailUnsubscribe]'s (AccountID).
//
// Generated from foreign key 'email_unsubscribes_account_id_fkey'.
func (eu *EmailUnsubscribe) AccountByAccountID(ctx context.Context, db DB) (*Account, error) {
	return AccountByID(ctx, db, eu.AccountID)
}

// EmailSendByEmailSendID returns the EmailSend associated with the [EmailUnsubscribe]'s (EmailSendID).
//
// Generated from foreign key 'email_unsubscribes_email_send_id_fkey'.
func (eu *EmailUnsubscribe) EmailSendByEmailSendID(ctx context.Context, db DB) (*EmailSend, error) {
	return EmailSendByID(ctx, db, Xid(eu.EmailSendID))
}

// EmailRecipientByRecipientID returns the EmailRecipient associated with the [EmailUnsubscribe]'s (RecipientID).
//
// Generated from foreign key 'email_unsubscribes_recipient_id_fkey'.
func (eu *EmailUnsubscribe) EmailRecipientByRecipientID(ctx context.Context, db DB) (*EmailRecipient, error) {
	return EmailRecipientByID(ctx, db, eu.RecipientID)
}
