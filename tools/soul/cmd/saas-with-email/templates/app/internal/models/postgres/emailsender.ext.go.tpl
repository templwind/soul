package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailSenderTableName                = "email_senders"
	EmailSenderFieldNames               = []string{"id","name","api_key","api_secret","username","password","smtp_server","smtp_port","api_url","additional_params","created_at","updated_at"}
	EmailSenderRows                     = "id,name,api_key,api_secret,username,password,smtp_server,smtp_port,api_url,additional_params,created_at,updated_at"
	EmailSenderRowsExpectAutoSet        = "name,api_key,api_secret,username,password,smtp_server,smtp_port,api_url,additional_params,created_at,updated_at"
	EmailSenderRowsWithPlaceHolder      = "name = $2, api_key = $3, api_secret = $4, username = $5, password = $6, smtp_server = $7, smtp_port = $8, api_url = $9, additional_params = $10, created_at = $11, updated_at = $12"
	EmailSenderRowsWithNamedPlaceHolder = "name = :name, api_key = :api_key, api_secret = :api_secret, username = :username, password = :password, smtp_server = :smtp_server, smtp_port = :smtp_port, api_url = :api_url, additional_params = :additional_params, created_at = :created_at, updated_at = :updated_at"
)

func FindAllEmailSenders(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailSender, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailSenderRows, EmailSenderTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailSenderRows, EmailSenderTableName, pageSize, offset)
    }

    var results []*EmailSender
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailSenderResponse struct {
	EmailSenders []EmailSender
	PagingStats    types.PagingStats
}

func SearchEmailSenders(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailSenderResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailSender{},
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
	for _, fieldName := range EmailSenderFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailSenderTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailSenderTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_senders
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_senders e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailSender EmailSender    `db:"email_senders"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailSender{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailSender)
	}

	out := &SearchEmailSenderResponse{
		EmailSenders: records,
		PagingStats:    *stats,
	}

	return out, err
}
