package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailSendTableName                = "email_sends"
	EmailSendFieldNames               = []string{"id","account_id","campaign_id","template_id","recipient_id","email_type_id","current_status","created_at","updated_at"}
	EmailSendRows                     = "id,account_id,campaign_id,template_id,recipient_id,email_type_id,current_status,created_at,updated_at"
	EmailSendRowsExpectAutoSet        = "account_id,campaign_id,template_id,recipient_id,email_type_id,current_status,created_at,updated_at"
	EmailSendRowsWithPlaceHolder      = "account_id = $2, campaign_id = $3, template_id = $4, recipient_id = $5, email_type_id = $6, current_status = $7, created_at = $8, updated_at = $9"
	EmailSendRowsWithNamedPlaceHolder = "account_id = :account_id, campaign_id = :campaign_id, template_id = :template_id, recipient_id = :recipient_id, email_type_id = :email_type_id, current_status = :current_status, created_at = :created_at, updated_at = :updated_at"
)

func FindAllEmailSends(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailSend, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailSendRows, EmailSendTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailSendRows, EmailSendTableName, pageSize, offset)
    }

    var results []*EmailSend
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailSendResponse struct {
	EmailSends []EmailSend
	PagingStats    types.PagingStats
}

func SearchEmailSends(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailSendResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailSend{},
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
	for _, fieldName := range EmailSendFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailSendTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailSendTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_sends
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_sends e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailSend EmailSend    `db:"email_sends"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailSend{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailSend)
	}

	out := &SearchEmailSendResponse{
		EmailSends: records,
		PagingStats:    *stats,
	}

	return out, err
}
