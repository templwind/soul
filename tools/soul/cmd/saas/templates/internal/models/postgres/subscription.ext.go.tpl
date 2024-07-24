package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	SubscriptionTableName                = "subscriptions"
	SubscriptionFieldNames               = []string{"id","public_id","user_id","product_id","start_date","end_date","status","created_at","updated_at"}
	SubscriptionRows                     = "id,public_id,user_id,product_id,start_date,end_date,status,created_at,updated_at"
	SubscriptionRowsExpectAutoSet        = "public_id,user_id,product_id,start_date,end_date,status,created_at,updated_at"
	SubscriptionRowsWithPlaceHolder      = "public_id = $2, user_id = $3, product_id = $4, start_date = $5, end_date = $6, status = $7, created_at = $8, updated_at = $9"
	SubscriptionRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, product_id = :product_id, start_date = :start_date, end_date = :end_date, status = :status, created_at = :created_at, updated_at = :updated_at"
)

func FindAllSubscriptions(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Subscription, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, SubscriptionRows, SubscriptionTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, SubscriptionRows, SubscriptionTableName, pageSize, offset)
    }

    var results []*Subscription
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchSubscriptionResponse struct {
	Subscriptions []Subscription
	PagingStats    types.PagingStats
}

func SearchSubscriptions(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchSubscriptionResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"S": Subscription{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY S.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range SubscriptionFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("S.%s as \"%s.%s\"", fieldName, SubscriptionTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", SubscriptionTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- subscriptions
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM subscriptions S
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Subscription Subscription    `db:"subscriptions"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Subscription{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Subscription)
	}

	out := &SearchSubscriptionResponse{
		Subscriptions: records,
		PagingStats:    *stats,
	}

	return out, err
}
