package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	ReviewTableName                = "reviews"
	ReviewFieldNames               = []string{"id","public_id","product_id","user_id","rating","content","created_at","updated_at"}
	ReviewRows                     = "id,public_id,product_id,user_id,rating,content,created_at,updated_at"
	ReviewRowsExpectAutoSet        = "public_id,product_id,user_id,rating,content,created_at,updated_at"
	ReviewRowsWithPlaceHolder      = "public_id = $2, product_id = $3, user_id = $4, rating = $5, content = $6, created_at = $7, updated_at = $8"
	ReviewRowsWithNamedPlaceHolder = "public_id = :public_id, product_id = :product_id, user_id = :user_id, rating = :rating, content = :content, created_at = :created_at, updated_at = :updated_at"
)

func FindAllReviews(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Review, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, ReviewRows, ReviewTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, ReviewRows, ReviewTableName, pageSize, offset)
    }

    var results []*Review
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchReviewResponse struct {
	Reviews []Review
	PagingStats    types.PagingStats
}

func SearchReviews(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchReviewResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"R": Review{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY R.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range ReviewFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("R.%s as \"%s.%s\"", fieldName, ReviewTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", ReviewTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- reviews
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM reviews R
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Review Review    `db:"reviews"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Review{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Review)
	}

	out := &SearchReviewResponse{
		Reviews: records,
		PagingStats:    *stats,
	}

	return out, err
}
