package db

import (
	"context"
	"log"

	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/db/setup"

	"github.com/jmoiron/sqlx"
	"github.com/pressly/goose/v3"
)

func up(db *sqlx.DB, c *config.Config) {
	// run sql migrations
	if err := goose.Up(db.DB, c.MigrationsPath); err != nil {
		log.Fatal("sql: error running goose up: ", err)
	}

	// run go migrations
	if err := goose.RunContext(context.Background(), "up", db.DB, c.MigrationsPath); err != nil {
		log.Fatal("go: error running goose up: ", err)
	}
}

func down(db *sqlx.DB, c *config.Config) error {
	// run sql migrations
	if err := goose.Down(db.DB, c.MigrationsPath); err != nil {
		log.Println("sql: error running goose down: ", err)
	}

	// run go migrations
	if err := goose.RunContext(context.Background(), "down", db.DB, c.MigrationsPath); err != nil {
		log.Println("go: error running goose down: ", err)
		return err
	}
	return nil
}

func mustRunMigrations(db *sqlx.DB, c *config.Config) {
	goose.SetDialect("sqlite3")
	goose.SetBaseFS(c.EmbededMigrations)

	// run the migrations
	up(db, c)

	// setup the custom migrations
	setUp := setup.NewSetup(db, c)

	var order int64 = 1
	nextOrderNum := func() int64 {
		order++
		return order
	}

	register := []*goose.Migration{
		goose.NewGoMigration(
			nextOrderNum(),
			&goose.GoFunc{RunDB: setUp.CreateDefaultAccount},
			&goose.GoFunc{RunDB: setUp.TearDownDefaultAccount},
		),
		goose.NewGoMigration(
			nextOrderNum(),
			&goose.GoFunc{RunDB: setUp.CreateUserTypes},
			&goose.GoFunc{RunDB: setUp.TearDownUserTypes},
		),
		goose.NewGoMigration(
			nextOrderNum(),
			&goose.GoFunc{RunDB: setUp.CreateTestUser},
			&goose.GoFunc{RunDB: setUp.TearDownTestUser},
		),
	}

	provider, err := goose.NewProvider(goose.DialectSQLite3, db.DB, nil,
		goose.WithGoMigrations(register...),
	)
	if err != nil {
		log.Fatal("goose: error creating provider: ", err)
	}

	_, err = provider.Up(context.Background())
	if err != nil {
		log.Fatal("goose: error running up: ", err)
	}

	// down(db, c)

	// for i := 0; i < 10; i++ {
	// 	if err := down(db, c); err != nil {
	// 		break
	// 	}
	// }

}
