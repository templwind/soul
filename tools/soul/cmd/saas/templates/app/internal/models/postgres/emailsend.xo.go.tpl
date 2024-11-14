package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"time"
)

// EmailSend represents a row from 'public.email_sends'.
type EmailSend struct {
	ID            Xid         `json:"id" db:"id" form:"id"`                                     // id
	AccountID     int64       `json:"account_id" db:"account_id" form:"account_id"`             // account_id
	CampaignID    NullXid     `json:"campaign_id" db:"campaign_id" form:"campaign_id"`          // campaign_id
	TemplateID    NullXid     `json:"template_id" db:"template_id" form:"template_id"`          // template_id
	RecipientID   Xid         `json:"recipient_id" db:"recipient_id" form:"recipient_id"`       // recipient_id
	EmailTypeID   int64       `json:"email_type_id" db:"email_type_id" form:"email_type_id"`    // email_type_id
	CurrentStatus EmailStatus `json:"current_status" db:"current_status" form:"current_status"` // current_status
	CreatedAt     time.Time   `json:"created_at" db:"created_at" form:"created_at"`             // created_at
	UpdatedAt     time.Time   `json:"updated_at" db:"updated_at" form:"updated_at"`             // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailSend] exists in the database.
func (es *EmailSend) Exists() bool {
	return es._exists
}

// Deleted returns true when the [EmailSend] has been marked for deletion
// from the database.
func (es *EmailSend) Deleted() bool {
	return es._deleted
}

// Insert inserts the [EmailSend] to the database.
func (es *EmailSend) Insert(ctx context.Context, db DB) error {
	switch {
	case es._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case es._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (manual)
	const sqlstr = `INSERT INTO public.email_sends (` +
		`id, account_id, campaign_id, template_id, recipient_id, email_type_id, current_status, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9` +
		`)`
	// run
	logf(sqlstr, es.ID, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, es.ID, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	es._exists = true
	return nil
}

// Update updates a [EmailSend] in the database.
func (es *EmailSend) Update(ctx context.Context, db DB) error {
	switch {
	case !es._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case es._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_sends SET ` +
		`account_id = $1, campaign_id = $2, template_id = $3, recipient_id = $4, email_type_id = $5, current_status = $6, created_at = $7, updated_at = $8 ` +
		`WHERE id = $9`
	// run
	logf(sqlstr, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt, es.ID)
	if _, err := db.ExecContext(ctx, sqlstr, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt, es.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailSend] to the database.
func (es *EmailSend) Save(ctx context.Context, db DB) error {
	if es.Exists() {
		return es.Update(ctx, db)
	}
	return es.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailSend].
func (es *EmailSend) Upsert(ctx context.Context, db DB) error {
	switch {
	case es._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_sends (` +
		`id, account_id, campaign_id, template_id, recipient_id, email_type_id, current_status, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`account_id = EXCLUDED.account_id, campaign_id = EXCLUDED.campaign_id, template_id = EXCLUDED.template_id, recipient_id = EXCLUDED.recipient_id, email_type_id = EXCLUDED.email_type_id, current_status = EXCLUDED.current_status, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, es.ID, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, es.ID, es.AccountID, es.CampaignID, es.TemplateID, es.RecipientID, es.EmailTypeID, es.CurrentStatus, es.CreatedAt, es.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	es._exists = true
	return nil
}

// Delete deletes the [EmailSend] from the database.
func (es *EmailSend) Delete(ctx context.Context, db DB) error {
	switch {
	case !es._exists: // doesn't exist
		return nil
	case es._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.email_sends ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, es.ID)
	if _, err := db.ExecContext(ctx, sqlstr, es.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	es._deleted = true
	return nil
}

// EmailSendByID retrieves a row from 'public.email_sends' as a [EmailSend].
//
// Generated from index 'email_sends_pkey'.
func EmailSendByID(ctx context.Context, db DB, id Xid) (*EmailSend, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, account_id, campaign_id, template_id, recipient_id, email_type_id, current_status, created_at, updated_at ` +
		`FROM public.email_sends ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	es := EmailSend{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&es.ID, &es.AccountID, &es.CampaignID, &es.TemplateID, &es.RecipientID, &es.EmailTypeID, &es.CurrentStatus, &es.CreatedAt, &es.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &es, nil
}

// AccountByAccountID returns the Account associated with the [EmailSend]'s (AccountID).
//
// Generated from foreign key 'email_sends_account_id_fkey'.
func (es *EmailSend) AccountByAccountID(ctx context.Context, db DB) (*Account, error) {
	return AccountByID(ctx, db, es.AccountID)
}

// EmailCampaignByCampaignID returns the EmailCampaign associated with the [EmailSend]'s (CampaignID).
//
// Generated from foreign key 'email_sends_campaign_id_fkey'.
func (es *EmailSend) EmailCampaignByCampaignID(ctx context.Context, db DB) (*EmailCampaign, error) {
	return EmailCampaignByID(ctx, db, Xid(es.CampaignID))
}

// EmailTypeByEmailTypeID returns the EmailType associated with the [EmailSend]'s (EmailTypeID).
//
// Generated from foreign key 'email_sends_email_type_id_fkey'.
func (es *EmailSend) EmailTypeByEmailTypeID(ctx context.Context, db DB) (*EmailType, error) {
	return EmailTypeByID(ctx, db, es.EmailTypeID)
}

// EmailRecipientByRecipientID returns the EmailRecipient associated with the [EmailSend]'s (RecipientID).
//
// Generated from foreign key 'email_sends_recipient_id_fkey'.
func (es *EmailSend) EmailRecipientByRecipientID(ctx context.Context, db DB) (*EmailRecipient, error) {
	return EmailRecipientByID(ctx, db, es.RecipientID)
}

// EmailTemplateByTemplateID returns the EmailTemplate associated with the [EmailSend]'s (TemplateID).
//
// Generated from foreign key 'email_sends_template_id_fkey'.
func (es *EmailSend) EmailTemplateByTemplateID(ctx context.Context, db DB) (*EmailTemplate, error) {
	return EmailTemplateByID(ctx, db, Xid(es.TemplateID))
}