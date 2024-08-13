package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	RolePermissionTableName                = "role_permissions"
	RolePermissionFieldNames               = []string{"role_id","permission_id"}
	RolePermissionRows                     = "role_id,permission_id"
	RolePermissionRowsExpectAutoSet        = "role_id,permission_id"
	RolePermissionRowsWithPlaceHolder      = "role_id = $2, permission_id = $3"
	RolePermissionRowsWithNamedPlaceHolder = "role_id = :role_id, permission_id = :permission_id"
)

func FindAllRolePermissions(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*RolePermission, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, RolePermissionRows, RolePermissionTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, RolePermissionRows, RolePermissionTableName, pageSize, offset)
    }

    var results []*RolePermission
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchRolePermissionResponse struct {
	RolePermissions []RolePermission
	PagingStats    types.PagingStats
}

func SearchRolePermissions(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchRolePermissionResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"R": RolePermission{},
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
	for _, fieldName := range RolePermissionFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("R.%s as \"%s.%s\"", fieldName, RolePermissionTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", RolePermissionTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- role_permissions
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM role_permissions R
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		RolePermission RolePermission    `db:"role_permissions"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []RolePermission{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.RolePermission)
	}

	out := &SearchRolePermissionResponse{
		RolePermissions: records,
		PagingStats:    *stats,
	}

	return out, err
}
