package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailOpenTableName                = "email_opens"
	EmailOpenFieldNames               = []string{"id", "email_send_id", "opened_at", "ip_address", "user_agent"}
	EmailOpenRows                     = "id,email_send_id,opened_at,ip_address,user_agent"
	EmailOpenRowsExpectAutoSet        = "email_send_id,opened_at,ip_address,user_agent"
	EmailOpenRowsWithPlaceHolder      = "email_send_id = $2, opened_at = $3, ip_address = $4, user_agent = $5"
	EmailOpenRowsWithNamedPlaceHolder = "email_send_id = :email_send_id, opened_at = :opened_at, ip_address = :ip_address, user_agent = :user_agent"
)

func FindAllEmailOpens(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailOpen, error) {
	var query string
	if pageSize == 0 {
		query = fmt.Sprintf(`SELECT %s FROM %s`, EmailOpenRows, EmailOpenTableName)
	} else {
		offset := (page - 1) * pageSize
		query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailOpenRows, EmailOpenTableName, pageSize, offset)
	}

	var results []*EmailOpen
	err := db.SelectContext(ctx, &results, query)
	if err != nil {
		return nil, err
	}
	return results, nil
}

// response type
type SearchEmailOpenResponse struct {
	EmailOpens  []EmailOpen
	PagingStats types.PagingStats
}

func SearchEmailOpens(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailOpenResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailOpen{},
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
	for _, fieldName := range EmailOpenFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailOpenTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailOpenTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_opens
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_opens e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailOpen   EmailOpen         `db:"email_opens"`
		PagingStats types.PagingStats `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailOpen{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailOpen)
	}

	out := &SearchEmailOpenResponse{
		EmailOpens:  records,
		PagingStats: *stats,
	}

	return out, err
}
