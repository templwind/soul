package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	AttachmentTableName                = "attachments"
	AttachmentFieldNames               = []string{"id","public_id","user_id","file_name","file_url","file_size","created_at","updated_at"}
	AttachmentRows                     = "id,public_id,user_id,file_name,file_url,file_size,created_at,updated_at"
	AttachmentRowsExpectAutoSet        = "public_id,user_id,file_name,file_url,file_size,created_at,updated_at"
	AttachmentRowsWithPlaceHolder      = "public_id = $2, user_id = $3, file_name = $4, file_url = $5, file_size = $6, created_at = $7, updated_at = $8"
	AttachmentRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, file_name = :file_name, file_url = :file_url, file_size = :file_size, created_at = :created_at, updated_at = :updated_at"
)

func FindAllAttachments(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Attachment, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, AttachmentRows, AttachmentTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, AttachmentRows, AttachmentTableName, pageSize, offset)
    }

    var results []*Attachment
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchAttachmentResponse struct {
	Attachments []Attachment
	PagingStats    types.PagingStats
}

func SearchAttachments(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchAttachmentResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"A": Attachment{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY A.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range AttachmentFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("A.%s as \"%s.%s\"", fieldName, AttachmentTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", AttachmentTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- attachments
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM attachments A
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Attachment Attachment    `db:"attachments"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Attachment{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Attachment)
	}

	out := &SearchAttachmentResponse{
		Attachments: records,
		PagingStats:    *stats,
	}

	return out, err
}
