package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	PostTableName                = "posts"
	PostFieldNames               = []string{"id","public_id","user_id","title","content","created_at","updated_at"}
	PostRows                     = "id,public_id,user_id,title,content,created_at,updated_at"
	PostRowsExpectAutoSet        = "public_id,user_id,title,content,created_at,updated_at"
	PostRowsWithPlaceHolder      = "public_id = $2, user_id = $3, title = $4, content = $5, created_at = $6, updated_at = $7"
	PostRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, title = :title, content = :content, created_at = :created_at, updated_at = :updated_at"
)

func FindAllPosts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Post, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, PostRows, PostTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, PostRows, PostTableName, pageSize, offset)
    }

    var results []*Post
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchPostResponse struct {
	Posts []Post
	PagingStats    types.PagingStats
}

func SearchPosts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchPostResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"P": Post{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY P.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range PostFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("P.%s as \"%s.%s\"", fieldName, PostTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", PostTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- posts
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM posts P
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Post Post    `db:"posts"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Post{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Post)
	}

	out := &SearchPostResponse{
		Posts: records,
		PagingStats:    *stats,
	}

	return out, err
}
