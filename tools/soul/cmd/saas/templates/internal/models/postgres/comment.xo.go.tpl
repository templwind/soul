package models

// Code generated by xo. DO NOT EDIT.

import (
	"context"
	"time"
)

// Comment represents a row from 'public.comments'.
type Comment struct {
	ID        int64        `json:"id" db:"id" form:"id"`                         // id
	PublicID  NullPublicID `json:"public_id" db:"public_id" form:"public_id"`    // public_id
	PostID    int64        `json:"post_id" db:"post_id" form:"post_id"`          // post_id
	UserID    int64        `json:"user_id" db:"user_id" form:"user_id"`          // user_id
	Content   string       `json:"content" db:"content" form:"content"`          // content
	CreatedAt time.Time    `json:"created_at" db:"created_at" form:"created_at"` // created_at
	UpdatedAt time.Time    `json:"updated_at" db:"updated_at" form:"updated_at"` // updated_at
	// xo fields
	_exists, _deleted bool
}

// Exists returns true when the [Comment] exists in the database.
func (c *Comment) Exists() bool {
	return c._exists
}

// Deleted returns true when the [Comment] has been marked for deletion
// from the database.
func (c *Comment) Deleted() bool {
	return c._deleted
}

// Insert inserts the [Comment] to the database.
func (c *Comment) Insert(ctx context.Context, db DB) error {
	switch {
	case c._exists: // already exists
		return logerror(&ErrInsertFailed{ErrAlreadyExists})
	case c._deleted: // deleted
		return logerror(&ErrInsertFailed{ErrMarkedForDeletion})
	}
	// insert (primary key generated and returned by database)
	const sqlstr = `INSERT INTO public.comments (` +
		`public_id, post_id, user_id, content, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6` +
		`) RETURNING id`
	// run
	logf(sqlstr, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt)
	if err := db.QueryRowContext(ctx, sqlstr, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt).Scan(&c.ID); err != nil {
		return logerror(err)
	}
	// set exists
	c._exists = true
	return nil
}

// Update updates a [Comment] in the database.
func (c *Comment) Update(ctx context.Context, db DB) error {
	switch {
	case !c._exists: // doesn't exist
		return logerror(&ErrUpdateFailed{ErrDoesNotExist})
	case c._deleted: // deleted
		return logerror(&ErrUpdateFailed{ErrMarkedForDeletion})
	}
	// update with composite primary key
	const sqlstr = `UPDATE public.comments SET ` +
		`public_id = $1, post_id = $2, user_id = $3, content = $4, created_at = $5, updated_at = $6 ` +
		`WHERE id = $7`
	// run
	logf(sqlstr, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt, c.ID)
	if _, err := db.ExecContext(ctx, sqlstr, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt, c.ID); err != nil {
		return logerror(err)
	}
	return nil
}

// Save saves the [Comment] to the database.
func (c *Comment) Save(ctx context.Context, db DB) error {
	if c.Exists() {
		return c.Update(ctx, db)
	}
	return c.Insert(ctx, db)
}

// Upsert performs an upsert for [Comment].
func (c *Comment) Upsert(ctx context.Context, db DB) error {
	switch {
	case c._deleted: // deleted
		return logerror(&ErrUpsertFailed{ErrMarkedForDeletion})
	}
	// upsert
	const sqlstr = `INSERT INTO public.comments (` +
		`id, public_id, post_id, user_id, content, created_at, updated_at` +
		`) VALUES (` +
		`$1, $2, $3, $4, $5, $6, $7` +
		`)` +
		` ON CONFLICT (id) DO ` +
		`UPDATE SET ` +
		`public_id = EXCLUDED.public_id, post_id = EXCLUDED.post_id, user_id = EXCLUDED.user_id, content = EXCLUDED.content, created_at = EXCLUDED.created_at, updated_at = EXCLUDED.updated_at `
	// run
	logf(sqlstr, c.ID, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt)
	if _, err := db.ExecContext(ctx, sqlstr, c.ID, c.PublicID, c.PostID, c.UserID, c.Content, c.CreatedAt, c.UpdatedAt); err != nil {
		return logerror(err)
	}
	// set exists
	c._exists = true
	return nil
}

// Delete deletes the [Comment] from the database.
func (c *Comment) Delete(ctx context.Context, db DB) error {
	switch {
	case !c._exists: // doesn't exist
		return nil
	case c._deleted: // deleted
		return nil
	}
	// delete with single primary key
	const sqlstr = `DELETE FROM public.comments ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, c.ID)
	if _, err := db.ExecContext(ctx, sqlstr, c.ID); err != nil {
		return logerror(err)
	}
	// set deleted
	c._deleted = true
	return nil
}

// CommentByID retrieves a row from 'public.comments' as a [Comment].
//
// Generated from index 'comments_pkey'.
func CommentByID(ctx context.Context, db DB, id int64) (*Comment, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, post_id, user_id, content, created_at, updated_at ` +
		`FROM public.comments ` +
		`WHERE id = $1`
	// run
	logf(sqlstr, id)
	c := Comment{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, id).Scan(&c.ID, &c.PublicID, &c.PostID, &c.UserID, &c.Content, &c.CreatedAt, &c.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &c, nil
}

// CommentByPublicID retrieves a row from 'public.comments' as a [Comment].
//
// Generated from index 'comments_public_id_key'.
func CommentByPublicID(ctx context.Context, db DB, publicID NullPublicID) (*Comment, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, post_id, user_id, content, created_at, updated_at ` +
		`FROM public.comments ` +
		`WHERE public_id = $1`
	// run
	logf(sqlstr, publicID)
	c := Comment{
		_exists: true,
	}
	if err := db.QueryRowContext(ctx, sqlstr, publicID).Scan(&c.ID, &c.PublicID, &c.PostID, &c.UserID, &c.Content, &c.CreatedAt, &c.UpdatedAt); err != nil {
		return nil, logerror(err)
	}
	return &c, nil
}

// CommentsByPostID retrieves a row from 'public.comments' as a [Comment].
//
// Generated from index 'idx_comments_post_id'.
func CommentsByPostID(ctx context.Context, db DB, postID int64) ([]*Comment, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, post_id, user_id, content, created_at, updated_at ` +
		`FROM public.comments ` +
		`WHERE post_id = $1`
	// run
	logf(sqlstr, postID)
	rows, err := db.QueryContext(ctx, sqlstr, postID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Comment
	for rows.Next() {
		c := Comment{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&c.ID, &c.PublicID, &c.PostID, &c.UserID, &c.Content, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &c)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// CommentsByUserID retrieves a row from 'public.comments' as a [Comment].
//
// Generated from index 'idx_comments_user_id'.
func CommentsByUserID(ctx context.Context, db DB, userID int64) ([]*Comment, error) {
	// query
	const sqlstr = `SELECT ` +
		`id, public_id, post_id, user_id, content, created_at, updated_at ` +
		`FROM public.comments ` +
		`WHERE user_id = $1`
	// run
	logf(sqlstr, userID)
	rows, err := db.QueryContext(ctx, sqlstr, userID)
	if err != nil {
		return nil, logerror(err)
	}
	defer rows.Close()
	// process
	var res []*Comment
	for rows.Next() {
		c := Comment{
			_exists: true,
		}
		// scan
		if err := rows.Scan(&c.ID, &c.PublicID, &c.PostID, &c.UserID, &c.Content, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, logerror(err)
		}
		res = append(res, &c)
	}
	if err := rows.Err(); err != nil {
		return nil, logerror(err)
	}
	return res, nil
}

// PostByPostID returns the Post associated with the [Comment]'s (PostID).
//
// Generated from foreign key 'comments_post_id_fkey'.
func (c *Comment) PostByPostID(ctx context.Context, db DB) (*Post, error) {
	return PostByID(ctx, db, c.PostID)
}

// UserByUserID returns the User associated with the [Comment]'s (UserID).
//
// Generated from foreign key 'comments_user_id_fkey'.
func (c *Comment) UserByUserID(ctx context.Context, db DB) (*User, error) {
	return UserByID(ctx, db, c.UserID)
}