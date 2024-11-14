package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// EmailMetric represents a row from 'public.email_metrics'.
type EmailMetric struct {
	Date         time.Time     `json:"date" db:"date" form:"date"`                               // date
	AccountID    int64         `json:"account_id" db:"account_id" form:"account_id"`             // account_id
	CampaignID   Xid           `json:"campaign_id" db:"campaign_id" form:"campaign_id"`          // campaign_id
	TemplateID   Xid           `json:"template_id" db:"template_id" form:"template_id"`          // template_id
	EmailTypeID  int64         `json:"email_type_id" db:"email_type_id" form:"email_type_id"`    // email_type_id
	Sent         sql.NullInt64 `json:"sent" db:"sent" form:"sent"`                               // sent
	Delivered    sql.NullInt64 `json:"delivered" db:"delivered" form:"delivered"`                // delivered
	Opened       sql.NullInt64 `json:"opened" db:"opened" form:"opened"`                         // opened
	Clicked      sql.NullInt64 `json:"clicked" db:"clicked" form:"clicked"`                      // clicked
	SoftBounced  sql.NullInt64 `json:"soft_bounced" db:"soft_bounced" form:"soft_bounced"`       // soft_bounced
	HardBounced  sql.NullInt64 `json:"hard_bounced" db:"hard_bounced" form:"hard_bounced"`       // hard_bounced
	Complained   sql.NullInt64 `json:"complained" db:"complained" form:"complained"`             // complained
	Unsubscribed sql.NullInt64 `json:"unsubscribed" db:"unsubscribed" form:"unsubscribed"`       // unsubscribed
	Failed       sql.NullInt64 `json:"failed" db:"failed" form:"failed"`                         // failed
	Deferred     sql.NullInt64 `json:"deferred" db:"deferred" form:"deferred"`                   // deferred
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailMetric] exists in the database.
func (em *EmailMetric) Exists() bool {
	return em._exists
}

// Deleted returns true when the [EmailMetric] has been marked for deletion
// from the database.
func (em *EmailMetric) Deleted() bool {
	return em._deleted
}

// Insert inserts the [EmailMetric] to the database.
func (em *EmailMetric) Insert(ctx context.Context, db DB) error {
	switch {
	case em._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case em._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (manual)
	const sqlstr = `INSERT INTO public.email_metrics (` +
		`date, account_id, campaign_id, template_id, email_type_id, sent, delivered, opened, clicked, soft_bounced, hard_bounced, complained, unsubscribed, failed, deferred` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15` +
		`)`
	// run
	logf(sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred)
	if _, err := db.ExecContext(ctx, sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred); err != nil {
		return logerror(err)
	}
	// set exists
	em._exists = true
	return nil
}

// Update updates a [EmailMetric] in the database.
func (em *EmailMetric) Update(ctx context.Context, db DB) error {
	switch {
	case !em._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case em._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_metrics SET ` +
		`sent = $1, delivered = $2, opened = $3, clicked = $4, soft_bounced = $5, hard_bounced = $6, complained = $7, unsubscribed = $8, failed = $9, deferred = $10 ` +
		`WHERE date = $11 AND account_id = $12 AND campaign_id = $13 AND template_id = $14 AND email_type_id = $15`
	// run
	logf(sqlstr, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID)
	if _, err := db.ExecContext(ctx, sqlstr, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailMetric] to the database.
func (em *EmailMetric) Save(ctx context.Context, db DB) error {
	if em.Exists() {
		return em.Update(ctx, db)
	}
	return em.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailMetric].
func (em *EmailMetric) Upsert(ctx context.Context, db DB) error {
	switch {
	case em._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_metrics (` +
		`date, account_id, campaign_id, template_id, email_type_id, sent, delivered, opened, clicked, soft_bounced, hard_bounced, complained, unsubscribed, failed, deferred` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15` +
		`)` +
		` ON CONFLICT (date, account_id, campaign_id, template_id, email_type_id) DO ` +
		`UPDATE SET ` +
		`sent = EXCLUDED.sent, delivered = EXCLUDED.delivered, opened = EXCLUDED.opened, clicked = EXCLUDED.clicked, soft_bounced = EXCLUDED.soft_bounced, hard_bounced = EXCLUDED.hard_bounced, complained = EXCLUDED.complained, unsubscribed = EXCLUDED.unsubscribed, failed = EXCLUDED.failed, deferred = EXCLUDED.deferred `
	// run
	logf(sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred)
	if _, err := db.ExecContext(ctx, sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID, em.Sent, em.Delivered, em.Opened, em.Clicked, em.SoftBounced, em.HardBounced, em.Complained, em.Unsubscribed, em.Failed, em.Deferred); err != nil {
		return logerror(err)
	}
	// set exists
	em._exists = true
	return nil
}

// Delete deletes the [EmailMetric] from the database.
func (em *EmailMetric) Delete(ctx context.Context, db DB) error {
	switch {
	case !em._exists: // doesn't exist
		return nil
	case em._deleted: // deleted
		return nil
	}
	// delete with composite primary key
	const sqlstr = `DELETE FROM public.email_metrics ` +
		`WHERE date = $1 AND account_id = $2 AND campaign_id = $3 AND template_id = $4 AND email_type_id = $5`
	// run
	logf(sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID)
	if _, err := db.ExecContext(ctx, sqlstr, em.Date, em.AccountID, em.CampaignID, em.TemplateID, em.EmailTypeID); err != nil {
		return logerror(err)
	}
	// set deleted
	em._deleted = true
	return nil
}

// AccountByAccountID returns the Account associated with the [EmailMetric]'s (AccountID).
//
// Generated from foreign key 'email_metrics_account_id_fkey'.
func (em *EmailMetric) AccountByAccountID(ctx context.Context, db DB) (*Account, error) {
	return AccountByID(ctx, db, em.AccountID)
}

// EmailCampaignByCampaignID returns the EmailCampaign associated with the [EmailMetric]'s (CampaignID).
//
// Generated from foreign key 'email_metrics_campaign_id_fkey'.
func (em *EmailMetric) EmailCampaignByCampaignID(ctx context.Context, db DB) (*EmailCampaign, error) {
	return EmailCampaignByID(ctx, db, em.CampaignID)
}

// EmailTypeByEmailTypeID returns the EmailType associated with the [EmailMetric]'s (EmailTypeID).
//
// Generated from foreign key 'email_metrics_email_type_id_fkey'.
func (em *EmailMetric) EmailTypeByEmailTypeID(ctx context.Context, db DB) (*EmailType, error) {
	return EmailTypeByID(ctx, db, em.EmailTypeID)
}

// EmailTemplateByTemplateID returns the EmailTemplate associated with the [EmailMetric]'s (TemplateID).
//
// Generated from foreign key 'email_metrics_template_id_fkey'.
func (em *EmailMetric) EmailTemplateByTemplateID(ctx context.Context, db DB) (*EmailTemplate, error) {
	return EmailTemplateByID(ctx, db, em.TemplateID)
}