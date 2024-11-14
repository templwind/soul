package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"time"
)

// EmailCampaign represents a row from 'public.email_campaigns'.
type EmailCampaign struct {
	ID           Xid       `json:"id" db:"id" form:"id"`                                     // id
	AccountID    int64     `json:"account_id" db:"account_id" form:"account_id"`             // account_id
	Name         string    `json:"name" db:"name" form:"name"`                               // name
	Subject      string    `json:"subject" db:"subject" form:"subject"`                      // subject
	EmailTypeID  int64     `json:"email_type_id" db:"email_type_id" form:"email_type_id"`    // email_type_id
	CreatedAt    time.Time `json:"created_at" db:"created_at" form:"created_at"`             // created_at
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at" form:"updated_at"`             // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailCampaign] exists in the database.
func (ec *EmailCampaign) Exists() bool {
	return ec._exists
}

// Deleted returns true when the [EmailCampaign] has been marked for deletion
// from the database.
func (ec *EmailCampaign) Deleted() bool {
	return ec._deleted
}

// Insert inserts the [EmailCampaign] to the database.
func (ec *EmailCampaign) Insert(ctx context.Context, db DB) error {
	switch {
	case ec._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case ec._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (manual)
	const sqlstr = `INSERT INTO public.email_campaigns (` +
		`id, account_id, name, subject, email_type_id, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7` +
		`)`
	// run
	logf(sqlstr, ec.ID, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, ec.ID, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	ec._exists = true
	return nil
}

// Update updates a [EmailCampaign] in the database.
func (ec *EmailCampaign) Update(ctx context.Context, db DB) error {
	switch {
	case !ec._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case ec._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_campaigns SET ` +
		`account_id = $1, name = $2, subject = $3, email_type_id = $4, created_at = $5, updated_at = $6 ` +
		`WHERE id = $8`
	// run
	logf(sqlstr, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt, ec.ID)
	if _, err := db.ExecContext(ctx, sqlstr, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt, ec.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailCampaign] to the database.
func (ec *EmailCampaign) Save(ctx context.Context, db DB) error {
	if ec.Exists() {
		return ec.Update(ctx, db)
	}
	return ec.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailCampaign].
func (ec *EmailCampaign) Upsert(ctx context.Context, db DB) error {
	switch {
	case ec._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_campaigns (` +
		`id, account_id, name, subject, email_type_id, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`account_id = EXCLUDED.account_id, name = EXCLUDED.name, subject = EXCLUDED.subject, email_type_id = EXCLUDED.email_type_id, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, ec.ID, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, ec.ID, ec.AccountID, ec.Name, ec.Subject, ec.EmailTypeID, ec.CreatedAt, ec.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	ec._exists = true
	return nil
}

// Delete deletes the [EmailCampaign] from the database.
func (ec *EmailCampaign) Delete(ctx context.Context, db DB) error {
	switch {
	case !ec._exists: // doesn't exist
		return nil
	case ec._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.email_campaigns ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, ec.ID)
	if _, err := db.ExecContext(ctx, sqlstr, ec.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	ec._deleted = true
	return nil
}

// EmailCampaignByID retrieves a row from 'public.email_campaigns' as a [EmailCampaign].
//
// Generated from index 'email_campaigns_pkey'.
func EmailCampaignByID(ctx context.Context, db DB, id Xid) (*EmailCampaign, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, name, subject, email_type_id, created_at, updated_at ` +
		`FROM public.email_campaigns ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	ec := EmailCampaign{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&ec.ID, &ec.AccountID, &ec.Name, &ec.Subject, &ec.EmailTypeID, &ec.CreatedAt, &ec.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &ec, nil
}

// AccountByAccountID returns the Account associated with the [EmailCampaign]'s (AccountID).
//
// Generated from foreign key 'email_campaigns_account_id_fkey'.
func (ec *EmailCampaign) AccountByAccountID(ctx context.Context, db DB) (*Account, error) {
	return AccountByID(ctx, db, ec.AccountID)
}

// EmailTypeByEmailTypeID returns the EmailType associated with the [EmailCampaign]'s (EmailTypeID).
//
// Generated from foreign key 'email_campaigns_email_type_id_fkey'.
func (ec *EmailCampaign) EmailTypeByEmailTypeID(ctx context.Context, db DB) (*EmailType, error) {
	return EmailTypeByID(ctx, db, ec.EmailTypeID)
}
