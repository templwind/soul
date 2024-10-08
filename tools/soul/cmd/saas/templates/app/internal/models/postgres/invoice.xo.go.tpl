package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// Invoice represents a row from 'public.invoices'.
type Invoice struct {
	ID             int64         `json:"id" db:"id" form:"id"`                                        // id
	PublicID       NullPublicID  `json:"public_id" db:"public_id" form:"public_id"`                   // public_id
	UserID         int64         `json:"user_id" db:"user_id" form:"user_id"`                         // user_id
	SubscriptionID sql.NullInt64 `json:"subscription_id" db:"subscription_id" form:"subscription_id"` // subscription_id
	Amount         float64       `json:"amount" db:"amount" form:"amount"`                            // amount
	Status         string        `json:"status" db:"status" form:"status"`                            // status
	InvoiceDate    time.Time     `json:"invoice_date" db:"invoice_date" form:"invoice_date"`          // invoice_date
	DueDate        sql.NullTime  `json:"due_date" db:"due_date" form:"due_date"`                      // due_date
	PaidDate       sql.NullTime  `json:"paid_date" db:"paid_date" form:"paid_date"`                   // paid_date
	CreatedAt      time.Time     `json:"created_at" db:"created_at" form:"created_at"`                // created_at
	UpdatedAt      time.Time     `json:"updated_at" db:"updated_at" form:"updated_at"`                // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [Invoice] exists in the database.
func (i *Invoice) Exists() bool {
	return i._exists
}

// Deleted returns true when the [Invoice] has been marked for deletion
// from the database.
func (i *Invoice) Deleted() bool {
	return i._deleted
}

// Insert inserts the [Invoice] to the database.
func (i *Invoice) Insert(ctx context.Context, db DB) error {
	switch {
	case i._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case i._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.invoices (` +
		`public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10` +
		`) RETURNING id`
	// run
	logf(sqlstr, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt).Scan(&i.ID); err != nil {
		return logerror(err)
	}
	// set exists
	i._exists = true
	return nil
}

// Update updates a [Invoice] in the database.
func (i *Invoice) Update(ctx context.Context, db DB) error {
	switch {
	case !i._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case i._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.invoices SET ` +
		`public_id = $1, user_id = $2, subscription_id = $3, amount = $4, status = $5, invoice_date = $6, due_date = $7, paid_date = $8, created_at = $9, updated_at = $10 ` +
		`WHERE id = $11`
	// run
	logf(sqlstr, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt, i.ID)
	if _, err := db.ExecContext(ctx, sqlstr, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt, i.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [Invoice] to the database.
func (i *Invoice) Save(ctx context.Context, db DB) error {
	if i.Exists() {
		return i.Update(ctx, db)
	}
	return i.Insert(ctx, db)
}

// Upsert performs an upsert for [Invoice].
func (i *Invoice) Upsert(ctx context.Context, db DB) error {
	switch {
	case i._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.invoices (` +
		`id, public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`public_id = EXCLUDED.public_id, user_id = EXCLUDED.user_id, subscription_id = EXCLUDED.subscription_id, amount = EXCLUDED.amount, status = EXCLUDED.status, invoice_date = EXCLUDED.invoice_date, due_date = EXCLUDED.due_date, paid_date = EXCLUDED.paid_date, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, i.ID, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, i.ID, i.PublicID, i.UserID, i.SubscriptionID, i.Amount, i.Status, i.InvoiceDate, i.DueDate, i.PaidDate, i.CreatedAt, i.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	i._exists = true
	return nil
}

// Delete deletes the [Invoice] from the database.
func (i *Invoice) Delete(ctx context.Context, db DB) error {
	switch {
	case !i._exists: // doesn't exist
		return nil
	case i._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.invoices ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, i.ID)
	if _, err := db.ExecContext(ctx, sqlstr, i.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	i._deleted = true
	return nil
}

// InvoicesBySubscriptionID retrieves a row from 'public.invoices' as a [Invoice].
//
// Generated from index 'idx_invoices_subscription_id'.
func InvoicesBySubscriptionID(ctx context.Context, db DB, subscriptionID sql.NullInt64) ([]*Invoice, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at ` +
		`FROM public.invoices ` +
		`WHERE subscription_id = $1`
	// run
	logf(sqlstr, subscriptionID)
	rows, err := db.QueryContext(ctx, sqlstr, subscriptionID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Invoice
	for rows.Next() {
		i := Invoice{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&i.ID, &i.PublicID, &i.UserID, &i.SubscriptionID, &i.Amount, &i.Status, &i.InvoiceDate, &i.DueDate, &i.PaidDate, &i.CreatedAt, &i.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &i)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// InvoicesByUserID retrieves a row from 'public.invoices' as a [Invoice].
//
// Generated from index 'idx_invoices_user_id'.
func InvoicesByUserID(ctx context.Context, db DB, userID int64) ([]*Invoice, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at ` +
		`FROM public.invoices ` +
		`WHERE user_id = $1`
	// run
	logf(sqlstr, userID)
	rows, err := db.QueryContext(ctx, sqlstr, userID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Invoice
	for rows.Next() {
		i := Invoice{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&i.ID, &i.PublicID, &i.UserID, &i.SubscriptionID, &i.Amount, &i.Status, &i.InvoiceDate, &i.DueDate, &i.PaidDate, &i.CreatedAt, &i.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &i)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// InvoiceByID retrieves a row from 'public.invoices' as a [Invoice].
//
// Generated from index 'invoices_pkey'.
func InvoiceByID(ctx context.Context, db DB, id int64) (*Invoice, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at ` +
		`FROM public.invoices ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	i := Invoice{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&i.ID, &i.PublicID, &i.UserID, &i.SubscriptionID, &i.Amount, &i.Status, &i.InvoiceDate, &i.DueDate, &i.PaidDate, &i.CreatedAt, &i.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &i, nil
}

// InvoiceByPublicID retrieves a row from 'public.invoices' as a [Invoice].
//
// Generated from index 'invoices_public_id_key'.
func InvoiceByPublicID(ctx context.Context, db DB, publicID NullPublicID) (*Invoice, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, user_id, subscription_id, amount, status, invoice_date, due_date, paid_date, created_at, updated_at ` +
		`FROM public.invoices ` +
		`WHERE public_id = $1`
	// run
	logf(sqlstr, publicID)
	i := Invoice{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, publicID).Scan(&i.ID, &i.PublicID, &i.UserID, &i.SubscriptionID, &i.Amount, &i.Status, &i.InvoiceDate, &i.DueDate, &i.PaidDate, &i.CreatedAt, &i.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &i, nil
}

// SubscriptionBySubscriptionID returns the Subscription associated with the [Invoice]'s (SubscriptionID).
//
// Generated from foreign key 'invoices_subscription_id_fkey'.
func (i *Invoice) SubscriptionBySubscriptionID(ctx context.Context, db DB) (*Subscription, error) {
	return SubscriptionByID(ctx, db, i.SubscriptionID.Int64)
}

// UserByUserID returns the User associated with the [Invoice]'s (UserID).
//
// Generated from foreign key 'invoices_user_id_fkey'.
func (i *Invoice) UserByUserID(ctx context.Context, db DB) (*User, error) {
	return UserByID(ctx, db, i.UserID)
}
