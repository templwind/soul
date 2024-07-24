package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	RoleTableName                = "roles"
	RoleFieldNames               = []string{"id","public_id","name","description","created_at","updated_at"}
	RoleRows                     = "id,public_id,name,description,created_at,updated_at"
	RoleRowsExpectAutoSet        = "public_id,name,description,created_at,updated_at"
	RoleRowsWithPlaceHolder      = "public_id = $2, name = $3, description = $4, created_at = $5, updated_at = $6"
	RoleRowsWithNamedPlaceHolder = "public_id = :public_id, name = :name, description = :description, created_at = :created_at, updated_at = :updated_at"
)

func FindAllRoles(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Role, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, RoleRows, RoleTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, RoleRows, RoleTableName, pageSize, offset)
    }

    var results []*Role
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchRoleResponse struct {
	Roles []Role
	PagingStats    types.PagingStats
}

func SearchRoles(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchRoleResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"R": Role{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY R.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range RoleFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("R.%s as \"%s.%s\"", fieldName, RoleTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", RoleTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- roles
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM roles R
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Role Role    `db:"roles"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Role{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Role)
	}

	out := &SearchRoleResponse{
		Roles: records,
		PagingStats:    *stats,
	}

	return out, err
}
