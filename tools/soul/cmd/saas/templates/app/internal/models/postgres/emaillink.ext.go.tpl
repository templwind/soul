package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailLinkTableName                = "email_links"
	EmailLinkFieldNames               = []string{"id","email_send_id","original_url","tracked_url","created_at"}
	EmailLinkRows                     = "id,email_send_id,original_url,tracked_url,created_at"
	EmailLinkRowsExpectAutoSet        = "email_send_id,original_url,tracked_url,created_at"
	EmailLinkRowsWithPlaceHolder      = "email_send_id = $2, original_url = $3, tracked_url = $4, created_at = $5"
	EmailLinkRowsWithNamedPlaceHolder = "email_send_id = :email_send_id, original_url = :original_url, tracked_url = :tracked_url, created_at = :created_at"
)

func FindAllEmailLinks(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailLink, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailLinkRows, EmailLinkTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailLinkRows, EmailLinkTableName, pageSize, offset)
    }

    var results []*EmailLink
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailLinkResponse struct {
	EmailLinks []EmailLink
	PagingStats    types.PagingStats
}

func SearchEmailLinks(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailLinkResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailLink{},
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
	for _, fieldName := range EmailLinkFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailLinkTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailLinkTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_links
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_links e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailLink EmailLink    `db:"email_links"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailLink{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailLink)
	}

	out := &SearchEmailLinkResponse{
		EmailLinks: records,
		PagingStats:    *stats,
	}

	return out, err
}
