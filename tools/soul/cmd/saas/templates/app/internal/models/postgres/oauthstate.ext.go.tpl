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
	OauthStateFieldNames               = []string{"id","provider","user_id","user_role_id","data","used","jwt_generated","created_at","expires_at"}
	OauthStateRows                     = "id,provider,user_id,user_role_id,data,used,jwt_generated,created_at,expires_at"
	OauthStateRowsExpectAutoSet        = "provider,user_id,user_role_id,data,used,jwt_generated,created_at,expires_at"
	OauthStateRowsWithPlaceHolder      = "provider = $2, user_id = $3, user_role_id = $4, data = $5, used = $6, jwt_generated = $7, created_at = $8, expires_at = $9"
	OauthStateRowsWithNamedPlaceHolder = "provider = :provider, user_id = :user_id, user_role_id = :user_role_id, data = :data, used = :used, jwt_generated = :jwt_generated, created_at = :created_at, expires_at = :expires_at"
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
		"o": OauthState{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY o.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range OauthStateFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("o.%s as \"%s.%s\"", fieldName, OauthStateTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", OauthStateTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- oauth_states
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM oauth_states o
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
