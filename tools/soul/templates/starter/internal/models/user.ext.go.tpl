package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .ModuleName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	UserTableName                = "users"
	UserFieldNames               = []string{"id", "name", "username", "email", "email_visibility", "last_reset_sent_at", "last_verification_sent_at", "password_hash", "token_key", "verified", "avatar", "type_id", "created_at", "updated_at"}
	UserRows                     = "id,name,username,email,email_visibility,last_reset_sent_at,last_verification_sent_at,password_hash,token_key,verified,avatar,type_id,created_at,updated_at"
	UserRowsExpectAutoSet        = "name,username,email,email_visibility,last_reset_sent_at,last_verification_sent_at,password_hash,token_key,verified,avatar,type_id,created_at,updated_at"
	UserRowsWithPlaceHolder      = "name = $2, username = $3, email = $4, email_visibility = $5, last_reset_sent_at = $6, last_verification_sent_at = $7, password_hash = $8, token_key = $9, verified = $10, avatar = $11, type_id = $12, created_at = $13, updated_at = $14"
	UserRowsWithNamedPlaceHolder = "name = :name, username = :username, email = :email, email_visibility = :email_visibility, last_reset_sent_at = :last_reset_sent_at, last_verification_sent_at = :last_verification_sent_at, password_hash = :password_hash, token_key = :token_key, verified = :verified, avatar = :avatar, type_id = :type_id, created_at = :created_at, updated_at = :updated_at"
)

func FindAllUsers(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*User, error) {
	var query string
	if pageSize == 0 {
		query = fmt.Sprintf(`SELECT %s FROM %s`, UserRows, UserTableName)
	} else {
		offset := (page - 1) * pageSize
		query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, UserRows, UserTableName, pageSize, offset)
	}

	var results []*User
	err := db.SelectContext(ctx, &results, query)
	if err != nil {
		return nil, err
	}
	return results, nil
}

// response type
type SearchUserResponse struct {
	Users       []User
	PagingStats types.PagingStats
}

func SearchUsers(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchUserResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"t1": User{},
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
	for _, fieldName := range UserFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("t1.%s as \"%s.%s\"", fieldName, UserTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", UserTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- users
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM users t1
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		User        User              `db:"users"`
		PagingStats types.PagingStats `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []User{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.User)
	}

	out := &SearchUserResponse{
		Users:       records,
		PagingStats: *stats,
	}

	return out, err
}
