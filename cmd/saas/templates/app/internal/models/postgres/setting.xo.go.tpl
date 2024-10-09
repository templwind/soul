package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// Setting represents a row from 'public.settings'.
type Setting struct {
	ID        int64         `json:"id" db:"id" form:"id"`                         // id
	PublicID  NullPublicID  `json:"public_id" db:"public_id" form:"public_id"`    // public_id
	UserID    sql.NullInt64 `json:"user_id" db:"user_id" form:"user_id"`          // user_id
	Key       string        `json:"key" db:"key" form:"key"`                      // key
	Value     string        `json:"value" db:"value" form:"value"`                // value
	CreatedAt time.Time     `json:"created_at" db:"created_at" form:"created_at"` // created_at
	UpdatedAt time.Time     `json:"updated_at" db:"updated_at" form:"updated_at"` // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [Setting] exists in the database.
func (s *Setting) Exists() bool {
	return s._exists
}

// Deleted returns true when the [Setting] has been marked for deletion
// from the database.
func (s *Setting) Deleted() bool {
	return s._deleted
}

// Insert inserts the [Setting] to the database.
func (s *Setting) Insert(ctx context.Context, db DB) error {
	switch {
	case s._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case s._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.settings (` +
		`public_id, user_id, key, value, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6` +
		`) RETURNING id`
	// run
	logf(sqlstr, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt).Scan(&s.ID); err != nil {
		return logerror(err)
	}
	// set exists
	s._exists = true
	return nil
}

// Update updates a [Setting] in the database.
func (s *Setting) Update(ctx context.Context, db DB) error {
	switch {
	case !s._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case s._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.settings SET ` +
		`public_id = $1, user_id = $2, key = $3, value = $4, created_at = $5, updated_at = $6 ` +
		`WHERE id = $7`
	// run
	logf(sqlstr, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt, s.ID)
	if _, err := db.ExecContext(ctx, sqlstr, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt, s.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [Setting] to the database.
func (s *Setting) Save(ctx context.Context, db DB) error {
	if s.Exists() {
		return s.Update(ctx, db)
	}
	return s.Insert(ctx, db)
}

// Upsert performs an upsert for [Setting].
func (s *Setting) Upsert(ctx context.Context, db DB) error {
	switch {
	case s._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.settings (` +
		`id, public_id, user_id, key, value, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`public_id = EXCLUDED.public_id, user_id = EXCLUDED.user_id, key = EXCLUDED.key, value = EXCLUDED.value, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, s.ID, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, s.ID, s.PublicID, s.UserID, s.Key, s.Value, s.CreatedAt, s.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	s._exists = true
	return nil
}

// Delete deletes the [Setting] from the database.
func (s *Setting) Delete(ctx context.Context, db DB) error {
	switch {
	case !s._exists: // doesn't exist
		return nil
	case s._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.settings ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, s.ID)
	if _, err := db.ExecContext(ctx, sqlstr, s.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	s._deleted = true
	return nil
}

// SettingsByUserID retrieves a row from 'public.settings' as a [Setting].
//
// Generated from index 'idx_settings_user_id'.
func SettingsByUserID(ctx context.Context, db DB, userID sql.NullInt64) ([]*Setting, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, key, value, created_at, updated_at ` +
		`FROM public.settings ` +
		`WHERE user_id = $1`
	// run
	logf(sqlstr, userID)
	rows, err := db.QueryContext(ctx, sqlstr, userID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Setting
	for rows.Next() {
		s := Setting{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&s.ID, &s.PublicID, &s.UserID, &s.Key, &s.Value, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &s)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// SettingByID retrieves a row from 'public.settings' as a [Setting].
//
// Generated from index 'settings_pkey'.
func SettingByID(ctx context.Context, db DB, id int64) (*Setting, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, key, value, created_at, updated_at ` +
		`FROM public.settings ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	s := Setting{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&s.ID, &s.PublicID, &s.UserID, &s.Key, &s.Value, &s.CreatedAt, &s.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &s, nil
}

// SettingByPublicID retrieves a row from 'public.settings' as a [Setting].
//
// Generated from index 'settings_public_id_key'.
func SettingByPublicID(ctx context.Context, db DB, publicID NullPublicID) (*Setting, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, key, value, created_at, updated_at ` +
		`FROM public.settings ` +
		`WHERE public_id = $1`
	// run
	logf(sqlstr, publicID)
	s := Setting{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, publicID).Scan(&s.ID, &s.PublicID, &s.UserID, &s.Key, &s.Value, &s.CreatedAt, &s.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &s, nil
}

// UserByUserID returns the User associated with the [Setting]'s (UserID).
//
// Generated from foreign key 'settings_user_id_fkey'.
func (s *Setting) UserByUserID(ctx context.Context, db DB) (*User, error) {
	return UserByID(ctx, db, s.UserID.Int64)
}
