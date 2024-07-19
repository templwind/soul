package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .ModuleName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	UserTypeTableName                = "user_types"
	UserTypeFieldNames               = []string{"id", "type_name", "description"}
	UserTypeRows                     = "id,type_name,description"
	UserTypeRowsExpectAutoSet        = "type_name,description"
	UserTypeRowsWithPlaceHolder      = "type_name = $2, description = $3"
	UserTypeRowsWithNamedPlaceHolder = "type_name = :type_name, description = :description"
)

func FindAllUserTypes(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*UserType, error) {
	var query string
	if pageSize == 0 {
		query = fmt.Sprintf(`SELECT %s FROM %s`, UserTypeRows, UserTypeTableName)
	} else {
		offset := (page - 1) * pageSize
		query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, UserTypeRows, UserTypeTableName, pageSize, offset)
	}

	var results []*UserType
	err := db.SelectContext(ctx, &results, query)
	if err != nil {
		return nil, err
	}
	return results, nil
}

// response type
type SearchUserTypeResponse struct {
	UserTypes   []UserType
	PagingStats types.PagingStats
}

func SearchUserTypes(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchUserTypeResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"t1": UserType{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY t1.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d, %d", currentPage*pageSize, pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range UserTypeFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("t1.%s as \"%s.%s\"", fieldName, UserTypeTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", UserTypeTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- user_types
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM user_types t1
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		UserType    UserType          `db:"user_types"`
		PagingStats types.PagingStats `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []UserType{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.UserType)
	}

	out := &SearchUserTypeResponse{
		UserTypes:   records,
		PagingStats: *stats,
	}

	return out, err
}
