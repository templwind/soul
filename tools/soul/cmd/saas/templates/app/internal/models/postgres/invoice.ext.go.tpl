package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	InvoiceTableName                = "invoices"
	InvoiceFieldNames               = []string{"id","public_id","user_id","subscription_id","amount","status","invoice_date","due_date","paid_date","created_at","updated_at"}
	InvoiceRows                     = "id,public_id,user_id,subscription_id,amount,status,invoice_date,due_date,paid_date,created_at,updated_at"
	InvoiceRowsExpectAutoSet        = "public_id,user_id,subscription_id,amount,status,invoice_date,due_date,paid_date,created_at,updated_at"
	InvoiceRowsWithPlaceHolder      = "public_id = $2, user_id = $3, subscription_id = $4, amount = $5, status = $6, invoice_date = $7, due_date = $8, paid_date = $9, created_at = $10, updated_at = $11"
	InvoiceRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, subscription_id = :subscription_id, amount = :amount, status = :status, invoice_date = :invoice_date, due_date = :due_date, paid_date = :paid_date, created_at = :created_at, updated_at = :updated_at"
)

func FindAllInvoices(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Invoice, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, InvoiceRows, InvoiceTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, InvoiceRows, InvoiceTableName, pageSize, offset)
    }

    var results []*Invoice
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchInvoiceResponse struct {
	Invoices []Invoice
	PagingStats    types.PagingStats
}

func SearchInvoices(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchInvoiceResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"I": Invoice{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY I.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range InvoiceFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("I.%s as \"%s.%s\"", fieldName, InvoiceTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", InvoiceTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- invoices
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM invoices I
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Invoice Invoice    `db:"invoices"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Invoice{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Invoice)
	}

	out := &SearchInvoiceResponse{
		Invoices: records,
		PagingStats:    *stats,
	}

	return out, err
}
