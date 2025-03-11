package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailRecipientTableName                = "email_recipients"
	EmailRecipientFieldNames               = []string{"id","account_id","email","name","created_at","updated_at"}
	EmailRecipientRows                     = "id,account_id,email,name,created_at,updated_at"
	EmailRecipientRowsExpectAutoSet        = "account_id,email,name,created_at,updated_at"
	EmailRecipientRowsWithPlaceHolder      = "account_id = $2, email = $3, name = $4, created_at = $5, updated_at = $6"
	EmailRecipientRowsWithNamedPlaceHolder = "account_id = :account_id, email = :email, name = :name, created_at = :created_at, updated_at = :updated_at"
)

func FindAllEmailRecipients(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailRecipient, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailRecipientRows, EmailRecipientTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailRecipientRows, EmailRecipientTableName, pageSize, offset)
    }

    var results []*EmailRecipient
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailRecipientResponse struct {
	EmailRecipients []EmailRecipient
	PagingStats    types.PagingStats
}

func SearchEmailRecipients(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailRecipientResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailRecipient{},
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
	for _, fieldName := range EmailRecipientFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailRecipientTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailRecipientTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_recipients
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_recipients e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailRecipient EmailRecipient    `db:"email_recipients"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailRecipient{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailRecipient)
	}

	out := &SearchEmailRecipientResponse{
		EmailRecipients: records,
		PagingStats:    *stats,
	}

	return out, err
}
