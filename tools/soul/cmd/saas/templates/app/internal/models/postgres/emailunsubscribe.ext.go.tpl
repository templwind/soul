package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailUnsubscribeTableName                = "email_unsubscribes"
	EmailUnsubscribeFieldNames               = []string{"id","account_id","recipient_id","email_send_id","unsubscribe_type","reason","unsubscribed_at","ip_address","user_agent"}
	EmailUnsubscribeRows                     = "id,account_id,recipient_id,email_send_id,unsubscribe_type,reason,unsubscribed_at,ip_address,user_agent"
	EmailUnsubscribeRowsExpectAutoSet        = "account_id,recipient_id,email_send_id,unsubscribe_type,reason,unsubscribed_at,ip_address,user_agent"
	EmailUnsubscribeRowsWithPlaceHolder      = "account_id = $2, recipient_id = $3, email_send_id = $4, unsubscribe_type = $5, reason = $6, unsubscribed_at = $7, ip_address = $8, user_agent = $9"
	EmailUnsubscribeRowsWithNamedPlaceHolder = "account_id = :account_id, recipient_id = :recipient_id, email_send_id = :email_send_id, unsubscribe_type = :unsubscribe_type, reason = :reason, unsubscribed_at = :unsubscribed_at, ip_address = :ip_address, user_agent = :user_agent"
)

func FindAllEmailUnsubscribes(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailUnsubscribe, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailUnsubscribeRows, EmailUnsubscribeTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailUnsubscribeRows, EmailUnsubscribeTableName, pageSize, offset)
    }

    var results []*EmailUnsubscribe
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailUnsubscribeResponse struct {
	EmailUnsubscribes []EmailUnsubscribe
	PagingStats    types.PagingStats
}

func SearchEmailUnsubscribes(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailUnsubscribeResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailUnsubscribe{},
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
	for _, fieldName := range EmailUnsubscribeFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailUnsubscribeTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailUnsubscribeTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_unsubscribes
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_unsubscribes e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailUnsubscribe EmailUnsubscribe    `db:"email_unsubscribes"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailUnsubscribe{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailUnsubscribe)
	}

	out := &SearchEmailUnsubscribeResponse{
		EmailUnsubscribes: records,
		PagingStats:    *stats,
	}

	return out, err
}
