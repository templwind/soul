package migrations

// import (
// 	"context"
// 	"echo-site/internal/config"
// 	"echo-site/internal/db/setup"
// 	"fmt"
// 	"log"

// 	"github.com/jmoiron/sqlx"
// 	"github.com/pressly/goose/v3"
// )

// // Options defines the options for the MigrationBuilder
// type Options struct {
// 	DB              *sqlx.DB
// 	Config          *config.Config
// 	Dialect         string
// 	Callbacks       []MigrationCallback
// 	EmbedMigrations bool
// }

// // MigrationCallback defines the signature for migration callback functions
// type MigrationCallback func(order int64) *goose.Migration

// // New creates a new MigrationBuilder component
// func New(opts ...OptFunc[Options]) *Options {
// 	return WithOptions(defaultProps, opts...)
// }

// // NewWithProps creates a new MigrationBuilder with the given properties
// func NewWithProps(opts *Options) *Options {
// 	return WithOptions(defaultProps, opts)
// }

// // WithOptions builds the options with the given opt
// func WithOptions(defaultProps func() *Options, opts ...OptFunc[Options]) *Options {
// 	p := defaultProps()
// 	for _, opt := range opts {
// 		opt(p)
// 	}
// 	return p
// }

// // OptFunc defines the signature for an option function
// type OptFunc[T any] func(*T)

// func defaultProps() *Options {
// 	return &Options{
// 		Dialect:         "",
// 		Callbacks:       make([]MigrationCallback, 0),
// 		EmbedMigrations: true,
// 	}
// }

// // WithDB sets the database
// func WithDB(db *sqlx.DB) OptFunc[Options] {
// 	return func(p *Options) {
// 		p.DB = db
// 	}
// }

// // WithConfig sets the configuration
// func WithConfig(cfg *config.Config) OptFunc[Options] {
// 	return func(p *Options) {
// 		p.Config = cfg
// 	}
// }

// // WithDialect sets the database dialect
// func WithDialect(dialect string) OptFunc[Options] {
// 	return func(p *Options) {
// 		p.Dialect = dialect
// 	}
// }

// // WithCallback adds a migration callback
// func WithCallback(callback MigrationCallback) OptFunc[Options] {
// 	return func(p *Options) {
// 		p.Callbacks = append(p.Callbacks, callback)
// 	}
// }

// // WithEmbedMigrations sets whether to use embedded migrations
// func WithEmbedMigrations(embed bool) OptFunc[Options] {
// 	return func(p *Options) {
// 		p.EmbedMigrations = embed
// 	}
// }

// // Run runs the migrations
// func Run(p *Options) {
// 	if p.Dialect == "" {
// 		log.Fatal("Database dialect must be set")
// 	}

// 	goose.SetDialect(p.Dialect)
// 	if p.EmbedMigrations {
// 		goose.SetBaseFS(p.Config.EmbedMigrations)
// 	}

// 	if err := runUp(p.DB, p.Config); err != nil {
// 		log.Fatal("Error running migrations: ", err)
// 	}

// 	// Setup the custom migrations
// 	setUp := setup.NewSetup(p.DB, p.Config)
// 	callbacks := append(DefaultMigrations(setUp), p.Callbacks...)
// 	migrations := RegisterMigrations(setUp, callbacks)

// 	provider, err := goose.NewProvider(p.Dialect, p.DB.DB, nil,
// 		goose.WithGoMigrations(migrations...),
// 	)
// 	if err != nil {
// 		log.Fatal("goose: error creating provider: ", err)
// 	}

// 	if _, err := provider.Up(context.Background()); err != nil {
// 		log.Fatal("goose: error running up: ", err)
// 	}
// }

// // runUp runs the SQL and Go migrations
// func runUp(db *sqlx.DB, cfg *config.Config) error {
// 	// Run SQL migrations
// 	if err := goose.Up(db.DB, cfg.MigrationsPath); err != nil {
// 		return fmt.Errorf("sql: error running goose up: %w", err)
// 	}

// 	// Run Go migrations
// 	if err := goose.RunContext(context.Background(), "up", db.DB, cfg.MigrationsPath); err != nil {
// 		return fmt.Errorf("go: error running goose up: %w", err)
// 	}

// 	return nil
// }

// // RegisterMigrations registers all the migrations using the provided callbacks
// func RegisterMigrations(setUp *setup.Setup, callbacks []MigrationCallback) []*goose.Migration {
// 	var order int64 = 1
// 	nextOrderNum := func() int64 {
// 		order++
// 		return order
// 	}

// 	migrations := make([]*goose.Migration, 0, len(callbacks))

// 	for _, callback := range callbacks {
// 		migrations = append(migrations, callback(nextOrderNum()))
// 	}

// 	return migrations
// }

// // DefaultMigrations returns the default set of migrations
// func DefaultMigrations(setUp *setup.Setup) []MigrationCallback {
// 	return []MigrationCallback{
// 		func(order int64) *goose.Migration {
// 			return goose.NewGoMigration(
// 				order,
// 				&goose.GoFunc{RunDB: setUp.CreateDefaultAccount},
// 				&goose.GoFunc{RunDB: setUp.TearDownDefaultAccount},
// 			)
// 		},
// 		func(order int64) *goose.Migration {
// 			return goose.NewGoMigration(
// 				order,
// 				&goose.GoFunc{RunDB: setUp.CreateUserTypes},
// 				&goose.GoFunc{RunDB: setUp.TearDownUserTypes},
// 			)
// 		},
// 		func(order int64) *goose.Migration {
// 			return goose.NewGoMigration(
// 				order,
// 				&goose.GoFunc{RunDB: setUp.CreateTestUser},
// 				&goose.GoFunc{RunDB: setUp.TearDownTestUser},
// 			)
// 		},
// 		func(order int64) *goose.Migration {
// 			return goose.NewGoMigration(
// 				order,
// 				&goose.GoFunc{RunDB: setUp.CreateDrUser},
// 				&goose.GoFunc{RunDB: setUp.TearDownDrUser},
// 			)
// 		},
// 	}
// }
