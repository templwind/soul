package types

type DBType string

func (db DBType) String() string {
	return string(db)
}

const (
	Postgres DBType = "postgres"
	MySql    DBType = "mysql"
	Sqlite   DBType = "sqlite"
)

type RouterType string

func (router RouterType) String() string {
	return string(router)
}

const (
	Echo   RouterType = "echo"
	Chi    RouterType = "chi"
	Gin    RouterType = "gin"
	Native RouterType = "native"
)
