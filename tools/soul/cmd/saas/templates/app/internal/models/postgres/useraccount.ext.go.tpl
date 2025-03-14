package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	UserAccountTableName                = "user_accounts"
	UserAccountFieldNames               = []string{"user_id","account_id"}
	UserAccountRows                     = "user_id,account_id"
	UserAccountRowsExpectAutoSet        = "user_id,account_id"
	UserAccountRowsWithPlaceHolder      = "user_id = $2, account_id = $3"
	UserAccountRowsWithNamedPlaceHolder = "user_id = :user_id, account_id = :account_id"
)

func FindAllUserAccounts(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*UserAccount, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, UserAccountRows, UserAccountTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, UserAccountRows, UserAccountTableName, pageSize, offset)
    }

    var results []*UserAccount
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchUserAccountResponse struct {
	UserAccounts []UserAccount
	PagingStats    types.PagingStats
}

func SearchUserAccounts(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchUserAccountResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"u": UserAccount{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY u.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range UserAccountFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("u.%s as \"%s.%s\"", fieldName, UserAccountTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", UserAccountTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- user_accounts
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM user_accounts u
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		UserAccount UserAccount    `db:"user_accounts"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []UserAccount{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.UserAccount)
	}

	out := &SearchUserAccountResponse{
		UserAccounts: records,
		PagingStats:    *stats,
	}

	return out, err
}
