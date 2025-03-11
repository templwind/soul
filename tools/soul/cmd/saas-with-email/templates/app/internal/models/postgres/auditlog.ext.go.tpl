package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	AuditLogTableName                = "audit_logs"
	AuditLogFieldNames               = []string{"id","public_id","user_id","action","entity","entity_id","details","created_at"}
	AuditLogRows                     = "id,public_id,user_id,action,entity,entity_id,details,created_at"
	AuditLogRowsExpectAutoSet        = "public_id,user_id,action,entity,entity_id,details,created_at"
	AuditLogRowsWithPlaceHolder      = "public_id = $2, user_id = $3, action = $4, entity = $5, entity_id = $6, details = $7, created_at = $8"
	AuditLogRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, action = :action, entity = :entity, entity_id = :entity_id, details = :details, created_at = :created_at"
)

func FindAllAuditLogs(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*AuditLog, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, AuditLogRows, AuditLogTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, AuditLogRows, AuditLogTableName, pageSize, offset)
    }

    var results []*AuditLog
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchAuditLogResponse struct {
	AuditLogs []AuditLog
	PagingStats    types.PagingStats
}

func SearchAuditLogs(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchAuditLogResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"A": AuditLog{},
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
	for _, fieldName := range AuditLogFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("A.%s as \"%s.%s\"", fieldName, AuditLogTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", AuditLogTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- audit_logs
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM audit_logs A
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		AuditLog AuditLog    `db:"audit_logs"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []AuditLog{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.AuditLog)
	}

	out := &SearchAuditLogResponse{
		AuditLogs: records,
		PagingStats:    *stats,
	}

	return out, err
}
