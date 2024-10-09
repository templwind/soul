package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	PaymentMethodTableName                = "payment_methods"
	PaymentMethodFieldNames               = []string{"id","public_id","user_id","type","details","is_primary","created_at","updated_at"}
	PaymentMethodRows                     = "id,public_id,user_id,type,details,is_primary,created_at,updated_at"
	PaymentMethodRowsExpectAutoSet        = "public_id,user_id,type,details,is_primary,created_at,updated_at"
	PaymentMethodRowsWithPlaceHolder      = "public_id = $2, user_id = $3, type = $4, details = $5, is_primary = $6, created_at = $7, updated_at = $8"
	PaymentMethodRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, type = :type, details = :details, is_primary = :is_primary, created_at = :created_at, updated_at = :updated_at"
)

func FindAllPaymentMethods(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*PaymentMethod, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, PaymentMethodRows, PaymentMethodTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, PaymentMethodRows, PaymentMethodTableName, pageSize, offset)
    }

    var results []*PaymentMethod
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchPaymentMethodResponse struct {
	PaymentMethods []PaymentMethod
	PagingStats    types.PagingStats
}

func SearchPaymentMethods(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchPaymentMethodResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"P": PaymentMethod{},
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
	for _, fieldName := range PaymentMethodFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("P.%s as \"%s.%s\"", fieldName, PaymentMethodTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", PaymentMethodTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- payment_methods
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM payment_methods P
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		PaymentMethod PaymentMethod    `db:"payment_methods"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []PaymentMethod{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.PaymentMethod)
	}

	out := &SearchPaymentMethodResponse{
		PaymentMethods: records,
		PagingStats:    *stats,
	}

	return out, err
}
