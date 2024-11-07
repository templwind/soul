package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailTypeTableName                = "email_types"
	EmailTypeFieldNames               = []string{"id","name"}
	EmailTypeRows                     = "id,name"
	EmailTypeRowsExpectAutoSet        = "name"
	EmailTypeRowsWithPlaceHolder      = "name = $2"
	EmailTypeRowsWithNamedPlaceHolder = "name = :name"
)

func FindAllEmailTypes(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailType, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailTypeRows, EmailTypeTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailTypeRows, EmailTypeTableName, pageSize, offset)
    }

    var results []*EmailType
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailTypeResponse struct {
	EmailTypes []EmailType
	PagingStats    types.PagingStats
}

func SearchEmailTypes(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailTypeResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailType{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY e.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range EmailTypeFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailTypeTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailTypeTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_types
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_types e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailType EmailType    `db:"email_types"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailType{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailType)
	}

	out := &SearchEmailTypeResponse{
		EmailTypes: records,
		PagingStats:    *stats,
	}

	return out, err
}
