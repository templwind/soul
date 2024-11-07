package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// EmailSender represents a row from 'public.email_senders'.
type EmailSender struct {
	ID               int64          `json:"id" db:"id" form:"id"`                                              // id
	Name             string         `json:"name" db:"name" form:"name"`                                        // name
	APIKey           sql.NullString `json:"api_key" db:"api_key" form:"api_key"`                               // api_key
	APISecret        sql.NullString `json:"api_secret" db:"api_secret" form:"api_secret"`                      // api_secret
	Username         sql.NullString `json:"username" db:"username" form:"username"`                            // username
	Password         sql.NullString `json:"password" db:"password" form:"password"`                            // password
	SMTPServer       sql.NullString `json:"smtp_server" db:"smtp_server" form:"smtp_server"`                   // smtp_server
	SMTPPort         sql.NullString `json:"smtp_port" db:"smtp_port" form:"smtp_port"`                         // smtp_port
	APIURL           sql.NullString `json:"api_url" db:"api_url" form:"api_url"`                               // api_url
	AdditionalParams []byte         `json:"additional_params" db:"additional_params" form:"additional_params"` // additional_params
	CreatedAt        time.Time      `json:"created_at" db:"created_at" form:"created_at"`                      // created_at
	UpdatedAt        time.Time      `json:"updated_at" db:"updated_at" form:"updated_at"`                      // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [EmailSender] exists in the database.
func (es *EmailSender) Exists() bool {
	return es._exists
}

// Deleted returns true when the [EmailSender] has been marked for deletion
// from the database.
func (es *EmailSender) Deleted() bool {
	return es._deleted
}

// Insert inserts the [EmailSender] to the database.
func (es *EmailSender) Insert(ctx context.Context, db DB) error {
	switch {
	case es._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case es._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.email_senders (` +
		`name, api_key, api_secret, username, password, smtp_server, smtp_port, api_url, additional_params, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11` +
		`) RETURNING id`
	// run
	logf(sqlstr, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt).Scan(&es.ID); err != nil {
		return logerror(err)
	}
	// set exists
	es._exists = true
	return nil
}

// Update updates a [EmailSender] in the database.
func (es *EmailSender) Update(ctx context.Context, db DB) error {
	switch {
	case !es._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case es._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.email_senders SET ` +
		`name = $1, api_key = $2, api_secret = $3, username = $4, password = $5, smtp_server = $6, smtp_port = $7, api_url = $8, additional_params = $9, created_at = $10, updated_at = $11 ` +
		`WHERE id = $12`
	// run
	logf(sqlstr, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt, es.ID)
	if _, err := db.ExecContext(ctx, sqlstr, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt, es.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [EmailSender] to the database.
func (es *EmailSender) Save(ctx context.Context, db DB) error {
	if es.Exists() {
		return es.Update(ctx, db)
	}
	return es.Insert(ctx, db)
}

// Upsert performs an upsert for [EmailSender].
func (es *EmailSender) Upsert(ctx context.Context, db DB) error {
	switch {
	case es._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.email_senders (` +
		`id, name, api_key, api_secret, username, password, smtp_server, smtp_port, api_url, additional_params, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`name = EXCLUDED.name, api_key = EXCLUDED.api_key, api_secret = EXCLUDED.api_secret, username = EXCLUDED.username, password = EXCLUDED.password, smtp_server = EXCLUDED.smtp_server, smtp_port = EXCLUDED.smtp_port, api_url = EXCLUDED.api_url, additional_params = EXCLUDED.additional_params, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, es.ID, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, es.ID, es.Name, es.APIKey, es.APISecret, es.Username, es.Password, es.SMTPServer, es.SMTPPort, es.APIURL, es.AdditionalParams, es.CreatedAt, es.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	es._exists = true
	return nil
}

// Delete deletes the [EmailSender] from the database.
func (es *EmailSender) Delete(ctx context.Context, db DB) error {
	switch {
	case !es._exists: // doesn't exist
		return nil
	case es._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.email_senders ` +
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

// EmailSenderByID retrieves a row from 'public.email_senders' as a [EmailSender].
//
// Generated from index 'email_senders_pkey'.
func EmailSenderByID(ctx context.Context, db DB, id int64) (*EmailSender, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, name, api_key, api_secret, username, password, smtp_server, smtp_port, api_url, additional_params, created_at, updated_at ` +
		`FROM public.email_senders ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	es := EmailSender{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&es.ID, &es.Name, &es.APIKey, &es.APISecret, &es.Username, &es.Password, &es.SMTPServer, &es.SMTPPort, &es.APIURL, &es.AdditionalParams, &es.CreatedAt, &es.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &es, nil
}
