package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// User represents a row from 'public.users'.
type User struct {
	ID                     int64        `json:"id" db:"id" form:"id"`                                                                      // id
	PublicID               NullPublicID `json:"public_id" db:"public_id" form:"public_id"`                                                 // public_id
	FirstName              string       `json:"first_name" db:"first_name" form:"first_name"`                                              // first_name
	LastName               string       `json:"last_name" db:"last_name" form:"last_name"`                                                 // last_name
	Title                  string       `json:"title" db:"title" form:"title"`                                                             // title
	Username               string       `json:"username" db:"username" form:"username"`                                                    // username
	Email                  string       `json:"email" db:"email" form:"email"`                                                             // email
	EmailVisibility        bool         `json:"email_visibility" db:"email_visibility" form:"email_visibility"`                            // email_visibility
	LastResetSentAt        sql.NullTime `json:"last_reset_sent_at" db:"last_reset_sent_at" form:"last_reset_sent_at"`                      // last_reset_sent_at
	LastVerificationSentAt sql.NullTime `json:"last_verification_sent_at" db:"last_verification_sent_at" form:"last_verification_sent_at"` // last_verification_sent_at
	PasswordHash           string       `json:"password_hash" db:"password_hash" form:"password_hash"`                                     // password_hash
	TokenKey               string       `json:"token_key" db:"token_key" form:"token_key"`                                                 // token_key
	Verified               bool         `json:"verified" db:"verified" form:"verified"`                                                    // verified
	Avatar                 string       `json:"avatar" db:"avatar" form:"avatar"`                                                          // avatar
	TypeID                 int64        `json:"type_id" db:"type_id" form:"type_id"`                                                       // type_id
	CreatedAt              time.Time    `json:"created_at" db:"created_at" form:"created_at"`                                              // created_at
	UpdatedAt              time.Time    `json:"updated_at" db:"updated_at" form:"updated_at"`                                              // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [User] exists in the database.
func (u *User) Exists() bool {
	return u._exists
}

// Deleted returns true when the [User] has been marked for deletion
// from the database.
func (u *User) Deleted() bool {
	return u._deleted
}

// Insert inserts the [User] to the database.
func (u *User) Insert(ctx context.Context, db DB) error {
	switch {
	case u._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case u._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.users (` +
		`public_id, first_name, last_name, title, username, email, email_visibility, last_reset_sent_at, last_verification_sent_at, password_hash, token_key, verified, avatar, type_id, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16` +
		`) RETURNING id`
	// run
	logf(sqlstr, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt).Scan(&u.ID); err != nil {
		return logerror(err)
	}
	// set exists
	u._exists = true
	return nil
}

// Update updates a [User] in the database.
func (u *User) Update(ctx context.Context, db DB) error {
	switch {
	case !u._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case u._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.users SET ` +
		`public_id = $1, first_name = $2, last_name = $3, title = $4, username = $5, email = $6, email_visibility = $7, last_reset_sent_at = $8, last_verification_sent_at = $9, password_hash = $10, token_key = $11, verified = $12, avatar = $13, type_id = $14, created_at = $15, updated_at = $16 ` +
		`WHERE id = $17`
	// run
	logf(sqlstr, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt, u.ID)
	if _, err := db.ExecContext(ctx, sqlstr, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt, u.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [User] to the database.
func (u *User) Save(ctx context.Context, db DB) error {
	if u.Exists() {
		return u.Update(ctx, db)
	}
	return u.Insert(ctx, db)
}

// Upsert performs an upsert for [User].
func (u *User) Upsert(ctx context.Context, db DB) error {
	switch {
	case u._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.users (` +
		`id, public_id, first_name, last_name, title, username, email, email_visibility, last_reset_sent_at, last_verification_sent_at, password_hash, token_key, verified, avatar, type_id, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`public_id = EXCLUDED.public_id, first_name = EXCLUDED.first_name, last_name = EXCLUDED.last_name, title = EXCLUDED.title, username = EXCLUDED.username, email = EXCLUDED.email, email_visibility = EXCLUDED.email_visibility, last_reset_sent_at = EXCLUDED.last_reset_sent_at, last_verification_sent_at = EXCLUDED.last_verification_sent_at, password_hash = EXCLUDED.password_hash, token_key = EXCLUDED.token_key, verified = EXCLUDED.verified, avatar = EXCLUDED.avatar, type_id = EXCLUDED.type_id, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, u.ID, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, u.ID, u.PublicID, u.FirstName, u.LastName, u.Title, u.Username, u.Email, u.EmailVisibility, u.LastResetSentAt, u.LastVerificationSentAt, u.PasswordHash, u.TokenKey, u.Verified, u.Avatar, u.TypeID, u.CreatedAt, u.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	u._exists = true
	return nil
}

// Delete deletes the [User] from the database.
func (u *User) Delete(ctx context.Context, db DB) error {
	switch {
	case !u._exists: // doesn't exist
		return nil
	case u._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.users ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, u.ID)
	if _, err := db.ExecContext(ctx, sqlstr, u.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	u._deleted = true
	return nil
}

// UserByEmail retrieves a row from 'public.users' as a [User].
//
// Generated from index 'users_email_key'.
func UserByEmail(ctx context.Context, db DB, email string) (*User, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, first_name, last_name, title, username, email, email_visibility, last_reset_sent_at, last_verification_sent_at, password_hash, token_key, verified, avatar, type_id, created_at, updated_at ` +
		`FROM public.users ` +
		`WHERE email = $1`
	// run
	logf(sqlstr, email)
	u := User{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, email).Scan(&u.ID, &u.PublicID, &u.FirstName, &u.LastName, &u.Title, &u.Username, &u.Email, &u.EmailVisibility, &u.LastResetSentAt, &u.LastVerificationSentAt, &u.PasswordHash, &u.TokenKey, &u.Verified, &u.Avatar, &u.TypeID, &u.CreatedAt, &u.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &u, nil
}

// UserByID retrieves a row from 'public.users' as a [User].
//
// Generated from index 'users_pkey'.
func UserByID(ctx context.Context, db DB, id int64) (*User, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, first_name, last_name, title, username, email, email_visibility, last_reset_sent_at, last_verification_sent_at, password_hash, token_key, verified, avatar, type_id, created_at, updated_at ` +
		`FROM public.users ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	u := User{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&u.ID, &u.PublicID, &u.FirstName, &u.LastName, &u.Title, &u.Username, &u.Email, &u.EmailVisibility, &u.LastResetSentAt, &u.LastVerificationSentAt, &u.PasswordHash, &u.TokenKey, &u.Verified, &u.Avatar, &u.TypeID, &u.CreatedAt, &u.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &u, nil
}

// UserByPublicID retrieves a row from 'public.users' as a [User].
//
// Generated from index 'users_public_id_key'.
func UserByPublicID(ctx context.Context, db DB, publicID NullPublicID) (*User, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, first_name, last_name, title, username, email, email_visibility, last_reset_sent_at, last_verification_sent_at, password_hash, token_key, verified, avatar, type_id, created_at, updated_at ` +
		`FROM public.users ` +
		`WHERE public_id = $1`
	// run
	logf(sqlstr, publicID)
	u := User{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, publicID).Scan(&u.ID, &u.PublicID, &u.FirstName, &u.LastName, &u.Title, &u.Username, &u.Email, &u.EmailVisibility, &u.LastResetSentAt, &u.LastVerificationSentAt, &u.PasswordHash, &u.TokenKey, &u.Verified, &u.Avatar, &u.TypeID, &u.CreatedAt, &u.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &u, nil
}

// UserTypeByTypeID returns the UserType associated with the [User]'s (TypeID).
//
// Generated from foreign key 'users_type_id_fkey'.
func (u *User) UserTypeByTypeID(ctx context.Context, db DB) (*UserType, error) {
	return UserTypeByID(ctx, db, u.TypeID)
}
