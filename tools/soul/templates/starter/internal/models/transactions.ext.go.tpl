package models

import (
	"context"
	"database/sql"
	"errors"

	"github.com/jmoiron/sqlx"
)

// DB is the common interface for database operations that can be used with
// This works with both [database/sql.DB] and [database/sql.Tx].
type SqlxDB interface {
	DB
	BindNamed(string, interface{}) (string, []interface{}, error)
	NamedQuery(query string, arg interface{}) (*sqlx.Rows, error)
	NamedExec(query string, arg interface{}) (sql.Result, error)
	PrepareNamedContext(context.Context, string) (*sqlx.NamedStmt, error)
	PrepareNamed(query string) (*sqlx.NamedStmt, error)
	Select(dest interface{}, query string, args ...interface{}) error
	SelectContext(ctx context.Context, dest interface{}, query string, args ...interface{}) error
	GetContext(ctx context.Context, dest interface{}, query string, args ...interface{}) error
	Get(dest interface{}, query string, args ...interface{}) error
}

type Transactions interface {
	Begin(ctx context.Context) error
	Commit() error
	Rollback() error
	GetTX() *sqlx.Tx
}

func NewTransactions(db *sqlx.DB) Transactions {
	return &transactions{db: db}
}

type transactions struct {
	db *sqlx.DB
	tx *sqlx.Tx
}

func (tm *transactions) GetTX() *sqlx.Tx {
	return tm.tx
}

func (tm *transactions) Begin(ctx context.Context) error {
	var err error
	tm.tx, err = tm.db.BeginTxx(ctx, nil)
	return err
}

func (tm *transactions) Commit() error {
	if tm.tx == nil {
		return errors.New("no transaction started")
	}
	err := tm.tx.Commit()
	tm.tx = nil
	return err
}

func (tm *transactions) Rollback() error {
	if tm.tx == nil {
		return errors.New("no transaction started")
	}
	err := tm.tx.Rollback()
	tm.tx = nil
	return err
}
