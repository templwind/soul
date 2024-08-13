package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	ProductTableName                = "products"
	ProductFieldNames               = []string{"id","public_id","name","description","price","is_subscription","created_at","updated_at"}
	ProductRows                     = "id,public_id,name,description,price,is_subscription,created_at,updated_at"
	ProductRowsExpectAutoSet        = "public_id,name,description,price,is_subscription,created_at,updated_at"
	ProductRowsWithPlaceHolder      = "public_id = $2, name = $3, description = $4, price = $5, is_subscription = $6, created_at = $7, updated_at = $8"
	ProductRowsWithNamedPlaceHolder = "public_id = :public_id, name = :name, description = :description, price = :price, is_subscription = :is_subscription, created_at = :created_at, updated_at = :updated_at"
)

func FindAllProducts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Product, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, ProductRows, ProductTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, ProductRows, ProductTableName, pageSize, offset)
    }

    var results []*Product
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchProductResponse struct {
	Products []Product
	PagingStats    types.PagingStats
}

func SearchProducts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchProductResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"P": Product{},
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
	for _, fieldName := range ProductFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("P.%s as \"%s.%s\"", fieldName, ProductTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", ProductTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- products
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM products P
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Product Product    `db:"products"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Product{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Product)
	}

	out := &SearchProductResponse{
		Products: records,
		PagingStats:    *stats,
	}

	return out, err
}
