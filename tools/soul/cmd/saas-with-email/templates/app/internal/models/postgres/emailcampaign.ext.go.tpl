package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailCampaignTableName                = "email_campaigns"
	EmailCampaignFieldNames               = []string{"id","account_id","name","subject","email_type_id","created_at","updated_at"}
	EmailCampaignRows                     = "id,account_id,name,subject,email_type_id,created_at,updated_at"
	EmailCampaignRowsExpectAutoSet        = "account_id,name,subject,email_type_id,created_at,updated_at"
	EmailCampaignRowsWithPlaceHolder      = "account_id = $2, name = $3, subject = $4, email_type_id = $5, created_at = $6, updated_at = $7"
	EmailCampaignRowsWithNamedPlaceHolder = "account_id = :account_id, name = :name, subject = :subject, email_type_id = :email_type_id, created_at = :created_at, updated_at = :updated_at"
)

func FindAllEmailCampaigns(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailCampaign, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailCampaignRows, EmailCampaignTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailCampaignRows, EmailCampaignTableName, pageSize, offset)
    }

    var results []*EmailCampaign
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailCampaignResponse struct {
	EmailCampaigns []EmailCampaign
	PagingStats    types.PagingStats
}

func SearchEmailCampaigns(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailCampaignResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailCampaign{},
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
	for _, fieldName := range EmailCampaignFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailCampaignTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailCampaignTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_campaigns
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_campaigns e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailCampaign EmailCampaign    `db:"email_campaigns"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailCampaign{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailCampaign)
	}

	out := &SearchEmailCampaignResponse{
		EmailCampaigns: records,
		PagingStats:    *stats,
	}

	return out, err
}
