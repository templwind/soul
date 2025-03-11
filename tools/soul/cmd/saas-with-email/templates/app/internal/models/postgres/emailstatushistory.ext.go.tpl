package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailStatusHistoryTableName                = "email_status_history"
	EmailStatusHistoryFieldNames               = []string{"id","account_id","email_send_id","status","changed_at","metadata"}
	EmailStatusHistoryRows                     = "id,account_id,email_send_id,status,changed_at,metadata"
	EmailStatusHistoryRowsExpectAutoSet        = "account_id,email_send_id,status,changed_at,metadata"
	EmailStatusHistoryRowsWithPlaceHolder      = "account_id = $2, email_send_id = $3, status = $4, changed_at = $5, metadata = $6"
	EmailStatusHistoryRowsWithNamedPlaceHolder = "account_id = :account_id, email_send_id = :email_send_id, status = :status, changed_at = :changed_at, metadata = :metadata"
)

func FindAllEmailStatusHistorys(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailStatusHistory, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailStatusHistoryRows, EmailStatusHistoryTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailStatusHistoryRows, EmailStatusHistoryTableName, pageSize, offset)
    }

    var results []*EmailStatusHistory
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailStatusHistoryResponse struct {
	EmailStatusHistorys []EmailStatusHistory
	PagingStats    types.PagingStats
}

func SearchEmailStatusHistorys(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailStatusHistoryResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailStatusHistory{},
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
	for _, fieldName := range EmailStatusHistoryFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailStatusHistoryTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailStatusHistoryTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_status_history
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_status_history e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailStatusHistory EmailStatusHistory    `db:"email_status_history"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailStatusHistory{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailStatusHistory)
	}

	out := &SearchEmailStatusHistoryResponse{
		EmailStatusHistorys: records,
		PagingStats:    *stats,
	}

	return out, err
}
