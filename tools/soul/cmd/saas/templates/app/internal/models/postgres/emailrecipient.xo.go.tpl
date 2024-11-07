package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// EmailRecipient represents a row from 'public.email_recipients'.
type EmailRecipient struct {
	ID        Xid            `json:"id" db:"id" form:"id"`                         // id
	AccountID int64          `json:"account_id" db:"account_id" form:"account_id"` // account_id
	Email     string         `json:"email" db:"email" form:"email"`                // email
	Name      sql.NullString `json:"name" db:"name" form:"name"`                   // name
	CreatedAt time.Time      `json:"created_at" db:"created_at" form:"created_at"` // created_at
	UpdatedAt time.Time      `json:"updated_at" db:"updated_at" form:"updated_at"` // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailRecipient] exists in the database.
func (er *EmailRecipient) Exists() bool {
	return er._exists
}

// Deleted returns true when the [EmailRecipient] has been marked for deletion
// from the database.
func (er *EmailRecipient) Deleted() bool {
	return er._deleted
}

// Insert inserts the [EmailRecipient] to the database.
func (er *EmailRecipient) Insert(ctx context.Context, db DB) error {
	switch {
	case er._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case er._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (manual)
	const sqlstr = `INSERT INTO public.email_recipients (` +
		`id, account_id, email, name, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6` +
		`)`
	// run
	logf(sqlstr, er.ID, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, er.ID, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	er._exists = true
	return nil
}

// Update updates a [EmailRecipient] in the database.
func (er *EmailRecipient) Update(ctx context.Context, db DB) error {
	switch {
	case !er._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case er._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_recipients SET ` +
		`account_id = $1, email = $2, name = $3, created_at = $4, updated_at = $5 ` +
		`WHERE id = $6`
	// run
	logf(sqlstr, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt, er.ID)
	if _, err := db.ExecContext(ctx, sqlstr, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt, er.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailRecipient] to the database.
func (er *EmailRecipient) Save(ctx context.Context, db DB) error {
	if er.Exists() {
		return er.Update(ctx, db)
	}
	return er.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailRecipient].
func (er *EmailRecipient) Upsert(ctx context.Context, db DB) error {
	switch {
	case er._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_recipients (` +
		`id, account_id, email, name, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`account_id = EXCLUDED.account_id, email = EXCLUDED.email, name = EXCLUDED.name, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, er.ID, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, er.ID, er.AccountID, er.Email, er.Name, er.CreatedAt, er.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	er._exists = true
	return nil
}

// Delete deletes the [EmailRecipient] from the database.
func (er *EmailRecipient) Delete(ctx context.Context, db DB) error {
	switch {
	case !er._exists: // doesn't exist
		return nil
	case er._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.email_recipients ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, er.ID)
	if _, err := db.ExecContext(ctx, sqlstr, er.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	er._deleted = true
	return nil
}

// EmailRecipientByID retrieves a row from 'public.email_recipients' as a [EmailRecipient].
//
// Generated from index 'email_recipients_pkey'.
func EmailRecipientByID(ctx context.Context, db DB, id Xid) (*EmailRecipient, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, email, name, created_at, updated_at ` +
		`FROM public.email_recipients ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	er := EmailRecipient{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&er.ID, &er.AccountID, &er.Email, &er.Name, &er.CreatedAt, &er.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &er, nil
}

// EmailRecipientsByAccountIDEmail retrieves a row from 'public.email_recipients' as a [EmailRecipient].
//
// Generated from index 'idx_email_recipients_account_id_email'.
func EmailRecipientsByAccountIDEmail(ctx context.Context, db DB, accountID int64, email string) ([]*EmailRecipient, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, email, name, created_at, updated_at ` +
		`FROM public.email_recipients ` +
		`WHERE account_id = $1 AND email = $2`
	// run
	logf(sqlstr, accountID, email)
	rows, err := db.QueryContext(ctx, sqlstr, accountID, email)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*EmailRecipient
	for rows.Next() {
		er := EmailRecipient{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&er.ID, &er.AccountID, &er.Email, &er.Name, &er.CreatedAt, &er.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &er)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// EmailRecipientsByEmail retrieves a row from 'public.email_recipients' as a [EmailRecipient].
//
// Generated from index 'idx_email_recipients_email'.
func EmailRecipientsByEmail(ctx context.Context, db DB, email string) ([]*EmailRecipient, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, email, name, created_at, updated_at ` +
		`FROM public.email_recipients ` +
		`WHERE email = $1`
	// run
	logf(sqlstr, email)
	rows, err := db.QueryContext(ctx, sqlstr, email)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*EmailRecipient
	for rows.Next() {
		er := EmailRecipient{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&er.ID, &er.AccountID, &er.Email, &er.Name, &er.CreatedAt, &er.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &er)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// AccountByAccountID returns the Account associated with the [EmailRecipient]'s (AccountID).
//
// Generated from foreign key 'email_recipients_account_id_fkey'.
func (er *EmailRecipient) AccountByAccountID(ctx context.Context, db DB) (*Account, error) {
	return AccountByID(ctx, db, er.AccountID)
}
