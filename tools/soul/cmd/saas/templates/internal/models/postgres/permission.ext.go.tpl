package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	PermissionTableName                = "permissions"
	PermissionFieldNames               = []string{"id","public_id","name","description","created_at","updated_at"}
	PermissionRows                     = "id,public_id,name,description,created_at,updated_at"
	PermissionRowsExpectAutoSet        = "public_id,name,description,created_at,updated_at"
	PermissionRowsWithPlaceHolder      = "public_id = $2, name = $3, description = $4, created_at = $5, updated_at = $6"
	PermissionRowsWithNamedPlaceHolder = "public_id = :public_id, name = :name, description = :description, created_at = :created_at, updated_at = :updated_at"
)

func FindAllPermissions(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Permission, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, PermissionRows, PermissionTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, PermissionRows, PermissionTableName, pageSize, offset)
    }

    var results []*Permission
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchPermissionResponse struct {
	Permissions []Permission
	PagingStats    types.PagingStats
}

func SearchPermissions(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchPermissionResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"P": Permission{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY P.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range PermissionFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("P.%s as \"%s.%s\"", fieldName, PermissionTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", PermissionTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- permissions
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM permissions P
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Permission Permission    `db:"permissions"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Permission{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Permission)
	}

	out := &SearchPermissionResponse{
		Permissions: records,
		PagingStats:    *stats,
	}

	return out, err
}
