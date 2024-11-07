package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailMetricTableName                = "email_metrics"
	EmailMetricFieldNames               = []string{"date","account_id","campaign_id","template_id","email_type_id","sent","delivered","opened","clicked","soft_bounced","hard_bounced","complained","unsubscribed","failed","deferred"}
	EmailMetricRows                     = "date,account_id,campaign_id,template_id,email_type_id,sent,delivered,opened,clicked,soft_bounced,hard_bounced,complained,unsubscribed,failed,deferred"
	EmailMetricRowsExpectAutoSet        = "date,account_id,campaign_id,template_id,email_type_id,sent,delivered,opened,clicked,soft_bounced,hard_bounced,complained,unsubscribed,failed,deferred"
	EmailMetricRowsWithPlaceHolder      = "date = $2, account_id = $3, campaign_id = $4, template_id = $5, email_type_id = $6, sent = $7, delivered = $8, opened = $9, clicked = $10, soft_bounced = $11, hard_bounced = $12, complained = $13, unsubscribed = $14, failed = $15, deferred = $16"
	EmailMetricRowsWithNamedPlaceHolder = "date = :date, account_id = :account_id, campaign_id = :campaign_id, template_id = :template_id, email_type_id = :email_type_id, sent = :sent, delivered = :delivered, opened = :opened, clicked = :clicked, soft_bounced = :soft_bounced, hard_bounced = :hard_bounced, complained = :complained, unsubscribed = :unsubscribed, failed = :failed, deferred = :deferred"
)

func FindAllEmailMetrics(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailMetric, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailMetricRows, EmailMetricTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailMetricRows, EmailMetricTableName, pageSize, offset)
    }

    var results []*EmailMetric
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailMetricResponse struct {
	EmailMetrics []EmailMetric
	PagingStats    types.PagingStats
}

func SearchEmailMetrics(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailMetricResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailMetric{},
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
	for _, fieldName := range EmailMetricFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailMetricTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailMetricTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_metrics
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_metrics e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailMetric EmailMetric    `db:"email_metrics"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailMetric{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailMetric)
	}

	out := &SearchEmailMetricResponse{
		EmailMetrics: records,
		PagingStats:    *stats,
	}

	return out, err
}
