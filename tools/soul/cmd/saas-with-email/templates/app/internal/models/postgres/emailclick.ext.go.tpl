package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailClickTableName                = "email_clicks"
	EmailClickFieldNames               = []string{"id","email_link_id","clicked_at","ip_address","user_agent"}
	EmailClickRows                     = "id,email_link_id,clicked_at,ip_address,user_agent"
	EmailClickRowsExpectAutoSet        = "email_link_id,clicked_at,ip_address,user_agent"
	EmailClickRowsWithPlaceHolder      = "email_link_id = $2, clicked_at = $3, ip_address = $4, user_agent = $5"
	EmailClickRowsWithNamedPlaceHolder = "email_link_id = :email_link_id, clicked_at = :clicked_at, ip_address = :ip_address, user_agent = :user_agent"
)

func FindAllEmailClicks(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailClick, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailClickRows, EmailClickTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailClickRows, EmailClickTableName, pageSize, offset)
    }

    var results []*EmailClick
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailClickResponse struct {
	EmailClicks []EmailClick
	PagingStats    types.PagingStats
}

func SearchEmailClicks(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailClickResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailClick{},
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
	for _, fieldName := range EmailClickFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailClickTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailClickTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_clicks
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_clicks e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailClick EmailClick    `db:"email_clicks"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailClick{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailClick)
	}

	out := &SearchEmailClickResponse{
		EmailClicks: records,
		PagingStats:    *stats,
	}

	return out, err
}
