package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	PaymentAttemptTableName                = "payment_attempts"
	PaymentAttemptFieldNames               = []string{"id","public_id","invoice_id","amount","status","gateway_response","attempt_date","created_at","updated_at"}
	PaymentAttemptRows                     = "id,public_id,invoice_id,amount,status,gateway_response,attempt_date,created_at,updated_at"
	PaymentAttemptRowsExpectAutoSet        = "public_id,invoice_id,amount,status,gateway_response,attempt_date,created_at,updated_at"
	PaymentAttemptRowsWithPlaceHolder      = "public_id = $2, invoice_id = $3, amount = $4, status = $5, gateway_response = $6, attempt_date = $7, created_at = $8, updated_at = $9"
	PaymentAttemptRowsWithNamedPlaceHolder = "public_id = :public_id, invoice_id = :invoice_id, amount = :amount, status = :status, gateway_response = :gateway_response, attempt_date = :attempt_date, created_at = :created_at, updated_at = :updated_at"
)

func FindAllPaymentAttempts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*PaymentAttempt, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, PaymentAttemptRows, PaymentAttemptTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, PaymentAttemptRows, PaymentAttemptTableName, pageSize, offset)
    }

    var results []*PaymentAttempt
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchPaymentAttemptResponse struct {
	PaymentAttempts []PaymentAttempt
	PagingStats    types.PagingStats
}

func SearchPaymentAttempts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchPaymentAttemptResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"P": PaymentAttempt{},
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
	for _, fieldName := range PaymentAttemptFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("P.%s as \"%s.%s\"", fieldName, PaymentAttemptTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", PaymentAttemptTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- payment_attempts
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM payment_attempts P
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		PaymentAttempt PaymentAttempt    `db:"payment_attempts"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []PaymentAttempt{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.PaymentAttempt)
	}

	out := &SearchPaymentAttemptResponse{
		PaymentAttempts: records,
		PagingStats:    *stats,
	}

	return out, err
}
