package models

import (
	"context"
	"fmt"
	"strings"

	"{{ .serviceName }}/internal/types"

	"github.com/localrivet/buildsql"
)

var (
	NotificationTableName                = "notifications"
	NotificationFieldNames               = []string{"id","public_id","user_id","message","read","created_at"}
	NotificationRows                     = "id,public_id,user_id,message,read,created_at"
	NotificationRowsExpectAutoSet        = "public_id,user_id,message,read,created_at"
	NotificationRowsWithPlaceHolder      = "public_id = $2, user_id = $3, message = $4, read = $5, created_at = $6"
	NotificationRowsWithNamedPlaceHolder = "public_id = :public_id, user_id = :user_id, message = :message, read = :read, created_at = :created_at"
)

func FindAllNotifications(ctx context.Context, db SqlxDB, page int, pageSize int) ([]*Notification, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf(`SELECT %s FROM %s`, NotificationRows, NotificationTableName)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf(`SELECT %s FROM %s LIMIT %d OFFSET %d`, NotificationRows, NotificationTableName, pageSize, offset)
    }

    var results []*Notification
    err := db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type SearchNotificationResponse struct {
	Notifications []Notification
	PagingStats    types.PagingStats
}

func SearchNotifications(ctx context.Context, db SqlxDB, currentPage, pageSize int64, filter string) (res *SearchNotificationResponse, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"N": Notification{},
	})
	if err != nil {
		return nil, err
	}

	if where != "" {
		where = fmt.Sprintf("WHERE 1 = 1 %s", where)
	}

	// set a default order by
	if orderBy == "" {
		orderBy = "ORDER BY N.id DESC"
	}
	limit := fmt.Sprintf("LIMIT %d OFFSET %d", pageSize, currentPage*pageSize)

	// field names
	var fieldNames []string
	for _, fieldName := range NotificationFieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("N.%s as \"%s.%s\"", fieldName, NotificationTableName, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", NotificationTableName)

	sql := fmt.Sprintf(`
		SELECT
			-- notifications
			%s,
			-- stats
			COUNT(*) OVER() AS "pagingstats.total_records"
		FROM notifications N
		%s
		%s
		%s
	`, strings.Join(fieldNames, ", "), where, orderBy, limit)

	nstmt, err := db.PrepareNamedContext(ctx, sql)

	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		Notification Notification    `db:"notifications"`
		PagingStats   types.PagingStats  `db:"pagingstats"`
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []Notification{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.Notification)
	}

	out := &SearchNotificationResponse{
		Notifications: records,
		PagingStats:    *stats,
	}

	return out, err
}
