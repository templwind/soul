package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	CommentTableName                = "comments"
	CommentFieldNames               = []string{"id","public_id","post_id","user_id","content","created_at","updated_at"}
	CommentRows                     = "id,public_id,post_id,user_id,content,created_at,updated_at"
	CommentRowsExpectAutoSet        = "public_id,post_id,user_id,content,created_at,updated_at"
	CommentRowsWithPlaceHolder      = "public_id = $2, post_id = $3, user_id = $4, content = $5, created_at = $6, updated_at = $7"
	CommentRowsWithNamedPlaceHolder = "public_id = :public_id, post_id = :post_id, user_id = :user_id, content = :content, created_at = :created_at, updated_at = :updated_at"
)

func FindAllComments(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Comment, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, CommentRows, CommentTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, CommentRows, CommentTableName, pageSize, offset)
    }

    var results []*Comment
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchCommentResponse struct {
	Comments []Comment
	PagingStats    types.PagingStats
}

func SearchComments(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchCommentResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"C": Comment{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY C.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range CommentFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("C.%s as \"%s.%s\"", fieldName, CommentTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", CommentTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- comments
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM comments C
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Comment Comment    `db:"comments"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Comment{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Comment)
	}

	out := &SearchCommentResponse{
		Comments: records,
		PagingStats:    *stats,
	}

	return out, err
}
