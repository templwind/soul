package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	SettingTableName                = "settings"
	SettingFieldNames               = []string{"id","public_id","user_id","key","value","created_at","updated_at"}
	SettingRows                     = "id,public_id,user_id,key,value,created_at,updated_at"
	SettingRowsExpectAutoSet        = "public_id,user_id,key,value,created_at,updated_at"
	SettingRowsWithPlaceHolder      = "public_id = $2, user_id = $3, key = $4, value = $5, created_at = $6, updated_at = $7"
	SettingRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, key = :key, value = :value, created_at = :created_at, updated_at = :updated_at"
)

func FindAllSettings(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Setting, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, SettingRows, SettingTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, SettingRows, SettingTableName, pageSize, offset)
    }

    var results []*Setting
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchSettingResponse struct {
	Settings []Setting
	PagingStats    types.PagingStats
}

func SearchSettings(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchSettingResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"S": Setting{},
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
	for _, fieldName := range SettingFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("S.%s as \"%s.%s\"", fieldName, SettingTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", SettingTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- settings
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM settings S
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Setting Setting    `db:"settings"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Setting{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Setting)
	}

	out := &SearchSettingResponse{
		Settings: records,
		PagingStats:    *stats,
	}

	return out, err
}
