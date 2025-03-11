package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	EmailTemplateTableName                = "email_templates"
	EmailTemplateFieldNames               = []string{"id","account_id","name","subject","email_type_id","content","created_at","updated_at"}
	EmailTemplateRows                     = "id,account_id,name,subject,email_type_id,content,created_at,updated_at"
	EmailTemplateRowsExpectAutoSet        = "account_id,name,subject,email_type_id,content,created_at,updated_at"
	EmailTemplateRowsWithPlaceHolder      = "account_id = $2, name = $3, subject = $4, email_type_id = $5, content = $6, created_at = $7, updated_at = $8"
	EmailTemplateRowsWithNamedPlaceHolder = "account_id = :account_id, name = :name, subject = :subject, email_type_id = :email_type_id, content = :content, created_at = :created_at, updated_at = :updated_at"
)

func FindAllEmailTemplates(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*EmailTemplate, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, EmailTemplateRows, EmailTemplateTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, EmailTemplateRows, EmailTemplateTableName, pageSize, offset)
    }

    var results []*EmailTemplate
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchEmailTemplateResponse struct {
	EmailTemplates []EmailTemplate
	PagingStats    types.PagingStats
}

func SearchEmailTemplates(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchEmailTemplateResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"e": EmailTemplate{},
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
	for _, fieldName := range EmailTemplateFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("e.%s as \"%s.%s\"", fieldName, EmailTemplateTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", EmailTemplateTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- email_templates
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM email_templates e
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		EmailTemplate EmailTemplate    `db:"email_templates"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []EmailTemplate{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.EmailTemplate)
	}

	out := &SearchEmailTemplateResponse{
		EmailTemplates: records,
		PagingStats:    *stats,
	}

	return out, err
}
