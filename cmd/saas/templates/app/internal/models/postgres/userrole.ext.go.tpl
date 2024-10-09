package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	UserRoleTableName                = "user_roles"
	UserRoleFieldNames               = []string{"user_id","role_id"}
	UserRoleRows                     = "user_id,role_id"
	UserRoleRowsExpectAutoSet        = "user_id,role_id"
	UserRoleRowsWithPlaceHolder      = "user_id = $2, role_id = $3"
	UserRoleRowsWithNamedPlaceHolder = "user_id = :user_id, role_id = :role_id"
)

func FindAllUserRoles(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*UserRole, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, UserRoleRows, UserRoleTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, UserRoleRows, UserRoleTableName, pageSize, offset)
    }

    var results []*UserRole
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchUserRoleResponse struct {
	UserRoles []UserRole
	PagingStats    types.PagingStats
}

func SearchUserRoles(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchUserRoleResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"U": UserRole{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY U.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range UserRoleFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("U.%s as \"%s.%s\"", fieldName, UserRoleTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", UserRoleTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- user_roles
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM user_roles U
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		UserRole UserRole    `db:"user_roles"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []UserRole{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.UserRole)
	}

	out := &SearchUserRoleResponse{
		UserRoles: records,
		PagingStats:    *stats,
	}

	return out, err
}
