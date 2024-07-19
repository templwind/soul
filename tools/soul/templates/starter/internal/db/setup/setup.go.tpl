package setup

import (
	"database/sql"

	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/models"

	"github.com/jmoiron/sqlx"
)

type Setup struct {
	c          *config.Config
	account1ID string
	account2ID string
	testUserID string
}

func NewSetup(db *sqlx.DB, c *config.Config) *Setup {
	return &Setup{
		c:          c,
		account1ID: models.NewID(db, "a"),
		account2ID: models.NewID(db, "a"),
		testUserID: models.NewID(db, "u"),
	}
}

func (s *Setup) boostDB(db *sql.DB) *sqlx.DB {
	return sqlx.NewDb(db, "sqlite3")
}
