package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// Subscription represents a row from 'public.subscriptions'.
type Subscription struct {
	ID        int64        `json:"id" db:"id" form:"id"`                         // id
	PublicID  NullPublicID `json:"public_id" db:"public_id" form:"public_id"`    // public_id
	UserID    int64        `json:"user_id" db:"user_id" form:"user_id"`          // user_id
	ProductID int64        `json:"product_id" db:"product_id" form:"product_id"` // product_id
	StartDate time.Time    `json:"start_date" db:"start_date" form:"start_date"` // start_date
	EndDate   sql.NullTime `json:"end_date" db:"end_date" form:"end_date"`       // end_date
	Status    string       `json:"status" db:"status" form:"status"`             // status
	CreatedAt time.Time    `json:"created_at" db:"created_at" form:"created_at"` // created_at
	UpdatedAt time.Time    `json:"updated_at" db:"updated_at" form:"updated_at"` // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [Subscription] exists in the database.
func (s *Subscription) Exists() bool {
	return s._exists
}

// Deleted returns true when the [Subscription] has been marked for deletion
// from the database.
func (s *Subscription) Deleted() bool {
	return s._deleted
}

// Insert inserts the [Subscription] to the database.
func (s *Subscription) Insert(ctx context.Context, db DB) error {
	switch {
	case s._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case s._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.subscriptions (` +
		`public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8` +
		`) RETURNING id`
	// run
	logf(sqlstr, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt).Scan(&s.ID); err != nil {
		return logerror(err)
	}
	// set exists
	s._exists = true
	return nil
}

// Update updates a [Subscription] in the database.
func (s *Subscription) Update(ctx context.Context, db DB) error {
	switch {
	case !s._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case s._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.subscriptions SET ` +
		`public_id = $1, user_id = $2, product_id = $3, start_date = $4, end_date = $5, status = $6, created_at = $7, updated_at = $8 ` +
		`WHERE id = $9`
	// run
	logf(sqlstr, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt, s.ID)
	if _, err := db.ExecContext(ctx, sqlstr, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt, s.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [Subscription] to the database.
func (s *Subscription) Save(ctx context.Context, db DB) error {
	if s.Exists() {
		return s.Update(ctx, db)
	}
	return s.Insert(ctx, db)
}

// Upsert performs an upsert for [Subscription].
func (s *Subscription) Upsert(ctx context.Context, db DB) error {
	switch {
	case s._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.subscriptions (` +
		`id, public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`public_id = EXCLUDED.public_id, user_id = EXCLUDED.user_id, product_id = EXCLUDED.product_id, start_date = EXCLUDED.start_date, end_date = EXCLUDED.end_date, status = EXCLUDED.status, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, s.ID, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, s.ID, s.PublicID, s.UserID, s.ProductID, s.StartDate, s.EndDate, s.Status, s.CreatedAt, s.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	s._exists = true
	return nil
}

// Delete deletes the [Subscription] from the database.
func (s *Subscription) Delete(ctx context.Context, db DB) error {
	switch {
	case !s._exists: // doesn't exist
		return nil
	case s._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.subscriptions ` +
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

// SubscriptionsByProductID retrieves a row from 'public.subscriptions' as a [Subscription].
//
// Generated from index 'idx_subscriptions_product_id'.
func SubscriptionsByProductID(ctx context.Context, db DB, productID int64) ([]*Subscription, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at ` +
		`FROM public.subscriptions ` +
		`WHERE product_id = $1`
	// run
	logf(sqlstr, productID)
	rows, err := db.QueryContext(ctx, sqlstr, productID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Subscription
	for rows.Next() {
		s := Subscription{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&s.ID, &s.PublicID, &s.UserID, &s.ProductID, &s.StartDate, &s.EndDate, &s.Status, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &s)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// SubscriptionsByUserID retrieves a row from 'public.subscriptions' as a [Subscription].
//
// Generated from index 'idx_subscriptions_user_id'.
func SubscriptionsByUserID(ctx context.Context, db DB, userID int64) ([]*Subscription, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at ` +
		`FROM public.subscriptions ` +
		`WHERE user_id = $1`
	// run
	logf(sqlstr, userID)
	rows, err := db.QueryContext(ctx, sqlstr, userID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Subscription
	for rows.Next() {
		s := Subscription{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&s.ID, &s.PublicID, &s.UserID, &s.ProductID, &s.StartDate, &s.EndDate, &s.Status, &s.CreatedAt, &s.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &s)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// SubscriptionByID retrieves a row from 'public.subscriptions' as a [Subscription].
//
// Generated from index 'subscriptions_pkey'.
func SubscriptionByID(ctx context.Context, db DB, id int64) (*Subscription, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at ` +
		`FROM public.subscriptions ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	s := Subscription{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&s.ID, &s.PublicID, &s.UserID, &s.ProductID, &s.StartDate, &s.EndDate, &s.Status, &s.CreatedAt, &s.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &s, nil
}

// SubscriptionByPublicID retrieves a row from 'public.subscriptions' as a [Subscription].
//
// Generated from index 'subscriptions_public_id_key'.
func SubscriptionByPublicID(ctx context.Context, db DB, publicID NullPublicID) (*Subscription, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, product_id, start_date, end_date, status, created_at, updated_at ` +
		`FROM public.subscriptions ` +
		`WHERE public_id = $1`
	// run
	logf(sqlstr, publicID)
	s := Subscription{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, publicID).Scan(&s.ID, &s.PublicID, &s.UserID, &s.ProductID, &s.StartDate, &s.EndDate, &s.Status, &s.CreatedAt, &s.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &s, nil
}

// ProductByProductID returns the Product associated with the [Subscription]'s (ProductID).
//
// Generated from foreign key 'subscriptions_product_id_fkey'.
func (s *Subscription) ProductByProductID(ctx context.Context, db DB) (*Product, error) {
	return ProductByID(ctx, db, s.ProductID)
}

// UserByUserID returns the User associated with the [Subscription]'s (UserID).
//
// Generated from foreign key 'subscriptions_user_id_fkey'.
func (s *Subscription) UserByUserID(ctx context.Context, db DB) (*User, error) {
	return UserByID(ctx, db, s.UserID)
}
