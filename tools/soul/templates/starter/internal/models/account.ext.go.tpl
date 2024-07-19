package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .ModuleName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	AccountTableName                = "accounts"
	AccountFieldNames               = []string{"id", "company_name", "address_1", "address_2", "city", "state_province", "postal_code", "country", "phone", "email", "website", "primary_user_id", "created_at", "updated_at"}
	AccountRows                     = "id,company_name,address_1,address_2,city,state_province,postal_code,country,phone,email,website,primary_user_id,created_at,updated_at"
	AccountRowsExpectAutoSet        = "company_name,address_1,address_2,city,state_province,postal_code,country,phone,email,website,primary_user_id,created_at,updated_at"
	AccountRowsWithPlaceHolder      = "company_name = $2, address_1 = $3, address_2 = $4, city = $5, state_province = $6, postal_code = $7, country = $8, phone = $9, email = $10, website = $11, primary_user_id = $12, created_at = $13, updated_at = $14"
	AccountRowsWithNamedPlaceHolder = "company_name = :company_name, address_1 = :address_1, address_2 = :address_2, city = :city, state_province = :state_province, postal_code = :postal_code, country = :country, phone = :phone, email = :email, website = :website, primary_user_id = :primary_user_id, created_at = :created_at, updated_at = :updated_at"
)

func FindAllAccounts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Account, error) {
	var query string
	if pageSize == 0 {
		query = fmt.Sprintf(`SELECT %s FROM %s`, AccountRows, AccountTableName)
	} else {
		offset := (page - 1) * pageSize
		query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, AccountRows, AccountTableName, pageSize, offset)
	}

	var results []*Account
	err := db.SelectContext(ctx, &results, query)
	if err != nil {
		return nil, err
	}
	return results, nil
}

// response type
type SearchAccountResponse struct {
	Accounts    []Account
	PagingStats types.PagingStats
}

func SearchAccounts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchAccountResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"t1": Account{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY t1.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d, %d", currentPage*pageSize, pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range AccountFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("t1.%s as \"%s.%s\"", fieldName, AccountTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", AccountTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- accounts
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM accounts t1
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Account     Account           `db:"accounts"`
		PagingStats types.PagingStats `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Account{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Account)
	}

	out := &SearchAccountResponse{
		Accounts:    records,
		PagingStats: *stats,
	}

	return out, err
}
