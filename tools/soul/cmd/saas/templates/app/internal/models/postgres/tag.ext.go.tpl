package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	TagTableName                = "tags"
	TagFieldNames               = []string{"id","public_id","tag","post_id","created_at","updated_at"}
	TagRows                     = "id,public_id,tag,post_id,created_at,updated_at"
	TagRowsExpectAutoSet        = "public_id,tag,post_id,created_at,updated_at"
	TagRowsWithPlaceHolder      = "public_id = $2, tag = $3, post_id = $4, created_at = $5, updated_at = $6"
	TagRowsWithNamedPlaceHolder = "public_id = :public_id, tag = :tag, post_id = :post_id, created_at = :created_at, updated_at = :updated_at"
)

func FindAllTags(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Tag, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, TagRows, TagTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, TagRows, TagTableName, pageSize, offset)
    }

    var results []*Tag
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchTagResponse struct {
	Tags []Tag
	PagingStats    types.PagingStats
}

func SearchTags(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchTagResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"T": Tag{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY T.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range TagFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("T.%s as \"%s.%s\"", fieldName, TagTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", TagTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- tags
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM tags T
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Tag Tag    `db:"tags"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Tag{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Tag)
	}

	out := &SearchTagResponse{
		Tags: records,
		PagingStats:    *stats,
	}

	return out, err
}