package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	AccountTableName                = "accounts"
	AccountFieldNames               = []string{"id","public_id","company_name","address_1","address_2","city","state_province","postal_code","country","phone","email","website","primary_user_id","created_at","updated_at"}
	AccountRows                     = "id,public_id,company_name,address_1,address_2,city,state_province,postal_code,country,phone,email,website,primary_user_id,created_at,updated_at"
	AccountRowsExpectAutoSet        = "public_id,company_name,address_1,address_2,city,state_province,postal_code,country,phone,email,website,primary_user_id,created_at,updated_at"
	AccountRowsWithPlaceHolder      = "public_id = $2, company_name = $3, address_1 = $4, address_2 = $5, city = $6, state_province = $7, postal_code = $8, country = $9, phone = $10, email = $11, website = $12, primary_user_id = $13, created_at = $14, updated_at = $15"
	AccountRowsWithNamedPlaceHolder = "public_id = :public_id, company_name = :company_name, address_1 = :address_1, address_2 = :address_2, city = :city, state_province = :state_province, postal_code = :postal_code, country = :country, phone = :phone, email = :email, website = :website, primary_user_id = :primary_user_id, created_at = :created_at, updated_at = :updated_at"
)

func FindAllAccounts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Account, error) {
    var query string
    if pageSize == 0{
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
	Accounts []Account
	PagingStats    types.PagingStats
}

func SearchAccounts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchAccountResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"A": Account{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY A.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range AccountFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("A.%s as \"%s.%s\"", fieldName, AccountTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", AccountTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- accounts
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM accounts A
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Account Account    `db:"accounts"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
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
		Accounts: records,
		PagingStats:    *stats,
	}

	return out, err
}
