package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"database/sql"
	"time"
)

// Bucket represents a row from 'public.buckets'.
type Bucket struct {
	ID         int            `json:"id" db:"id" form:"id"`                            // id
	BucketName string         `json:"bucket_name" db:"bucket_name" form:"bucket_name"` // bucket_name
	Region     sql.NullString `json:"region" db:"region" form:"region"`                // region
	TotalSize  int64          `json:"total_size" db:"total_size" form:"total_size"`    // total_size
	IsPrimary  bool           `json:"is_primary" db:"is_primary" form:"is_primary"`    // is_primary
	CreatedAt  time.Time      `json:"created_at" db:"created_at" form:"created_at"`    // created_at
	UpdatedAt  time.Time      `json:"updated_at" db:"updated_at" form:"updated_at"`    // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [Bucket] exists in the database.
func (b *Bucket) Exists() bool {
	return b._exists
}

// Deleted returns true when the [Bucket] has been marked for deletion
// from the database.
func (b *Bucket) Deleted() bool {
	return b._deleted
}

// Insert inserts the [Bucket] to the database.
func (b *Bucket) Insert(ctx context.Context, db DB) error {
	switch {
	case b._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case b._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.buckets (` +
		`bucket_name, region, total_size, is_primary, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6` +
		`) RETURNING id`
	// run
	logf(sqlstr, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt).Scan(&b.ID); err != nil {
		return logerror(err)
	}
	// set exists
	b._exists = true
	return nil
}

// Update updates a [Bucket] in the database.
func (b *Bucket) Update(ctx context.Context, db DB) error {
	switch {
	case !b._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case b._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.buckets SET ` +
		`bucket_name = $1, region = $2, total_size = $3, is_primary = $4, created_at = $5, updated_at = $6 ` +
		`WHERE id = $7`
	// run
	logf(sqlstr, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt, b.ID)
	if _, err := db.ExecContext(ctx, sqlstr, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt, b.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [Bucket] to the database.
func (b *Bucket) Save(ctx context.Context, db DB) error {
	if b.Exists() {
		return b.Update(ctx, db)
	}
	return b.Insert(ctx, db)
}

// Upsert performs an upsert for [Bucket].
func (b *Bucket) Upsert(ctx context.Context, db DB) error {
	switch {
	case b._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.buckets (` +
		`id, bucket_name, region, total_size, is_primary, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`bucket_name = EXCLUDED.bucket_name, region = EXCLUDED.region, total_size = EXCLUDED.total_size, is_primary = EXCLUDED.is_primary, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, b.ID, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, b.ID, b.BucketName, b.Region, b.TotalSize, b.IsPrimary, b.CreatedAt, b.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	b._exists = true
	return nil
}

// Delete deletes the [Bucket] from the database.
func (b *Bucket) Delete(ctx context.Context, db DB) error {
	switch {
	case !b._exists: // doesn't exist
		return nil
	case b._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.buckets ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, b.ID)
	if _, err := db.ExecContext(ctx, sqlstr, b.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	b._deleted = true
	return nil
}

// BucketByBucketName retrieves a row from 'public.buckets' as a [Bucket].
//
// Generated from index 'buckets_bucket_name_key'.
func BucketByBucketName(ctx context.Context, db DB, bucketName string) (*Bucket, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, bucket_name, region, total_size, is_primary, created_at, updated_at ` +
		`FROM public.buckets ` +
		`WHERE bucket_name = $1`
	// run
	logf(sqlstr, bucketName)
	b := Bucket{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, bucketName).Scan(&b.ID, &b.BucketName, &b.Region, &b.TotalSize, &b.IsPrimary, &b.CreatedAt, &b.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &b, nil
}

// BucketByID retrieves a row from 'public.buckets' as a [Bucket].
//
// Generated from index 'buckets_pkey'.
func BucketByID(ctx context.Context, db DB, id int) (*Bucket, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, bucket_name, region, total_size, is_primary, created_at, updated_at ` +
		`FROM public.buckets ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	b := Bucket{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&b.ID, &b.BucketName, &b.Region, &b.TotalSize, &b.IsPrimary, &b.CreatedAt, &b.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &b, nil
}

// BucketByIsPrimary retrieves a row from 'public.buckets' as a [Bucket].
//
// Generated from index 'unique_primary_bucket'.
func BucketByIsPrimary(ctx context.Context, db DB, isPrimary bool) (*Bucket, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, bucket_name, region, total_size, is_primary, created_at, updated_at ` +
		`FROM public.buckets ` +
		`WHERE is_primary = $1`
	// run
	logf(sqlstr, isPrimary)
	b := Bucket{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, isPrimary).Scan(&b.ID, &b.BucketName, &b.Region, &b.TotalSize, &b.IsPrimary, &b.CreatedAt, &b.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &b, nil
}
