package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	OauthStateTableName                = "oauth_states"
	OauthStateFieldNames               = []string{"id","public_id","provider","user_id","user_role_id","data","used","jwt_generated","created_at","expires_at"}
	OauthStateRows                     = "id,public_id,provider,user_id,user_role_id,data,used,jwt_generated,created_at,expires_at"
	OauthStateRowsExpectAutoSet        = "public_id,provider,user_id,user_role_id,data,used,jwt_generated,created_at,expires_at"
	OauthStateRowsWithPlaceHolder      = "public_id = $2, provider = $3, user_id = $4, user_role_id = $5, data = $6, used = $7, jwt_generated = $8, created_at = $9, expires_at = $10"
	OauthStateRowsWithNamedPlaceHolder = "public_id = :public_id, provider = :provider, user_id = :user_id, user_role_id = :user_role_id, data = :data, used = :used, jwt_generated = :jwt_generated, created_at = :created_at, expires_at = :expires_at"
)

func FindAllOauthStates(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*OauthState, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, OauthStateRows, OauthStateTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, OauthStateRows, OauthStateTableName, pageSize, offset)
    }

    var results []*OauthState
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchOauthStateResponse struct {
	OauthStates []OauthState
	PagingStats    types.PagingStats
}

func SearchOauthStates(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchOauthStateResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"O": OauthState{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY O.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range OauthStateFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("O.%s as \"%s.%s\"", fieldName, OauthStateTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", OauthStateTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- oauth_states
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM oauth_states O
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		OauthState OauthState    `db:"oauth_states"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []OauthState{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.OauthState)
	}

	out := &SearchOauthStateResponse{
		OauthStates: records,
		PagingStats:    *stats,
	}

	return out, err
}
