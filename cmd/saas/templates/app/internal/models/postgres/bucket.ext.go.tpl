package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	BucketTableName                = "buckets"
	BucketFieldNames               = []string{"id","bucket_name","region","total_size","is_primary","created_at","updated_at"}
	BucketRows                     = "id,bucket_name,region,total_size,is_primary,created_at,updated_at"
	BucketRowsExpectAutoSet        = "bucket_name,region,total_size,is_primary,created_at,updated_at"
	BucketRowsWithPlaceHolder      = "bucket_name = $2, region = $3, total_size = $4, is_primary = $5, created_at = $6, updated_at = $7"
	BucketRowsWithNamedPlaceHolder = "bucket_name = :bucket_name, region = :region, total_size = :total_size, is_primary = :is_primary, created_at = :created_at, updated_at = :updated_at"
)

func FindAllBuckets(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Bucket, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, BucketRows, BucketTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, BucketRows, BucketTableName, pageSize, offset)
    }

    var results []*Bucket
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchBucketResponse struct {
	Buckets []Bucket
	PagingStats    types.PagingStats
}

func SearchBuckets(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchBucketResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"b": Bucket{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY b.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range BucketFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("b.%s as \"%s.%s\"", fieldName, BucketTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", BucketTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- buckets
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM buckets b
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Bucket Bucket    `db:"buckets"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Bucket{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Bucket)
	}

	out := &SearchBucketResponse{
		Buckets: records,
		PagingStats:    *stats,
	}

	return out, err
}
