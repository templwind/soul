package parsexo

const CustomInterfaceTemplate = `{{- $modelName := .ModelName -}}
{{- $includePkg := .IncludePackageName -}}
{{- $originalPkg := .OriginalPackageName -}}
{{- $functionSignatures := .FunctionSignatures -}}
package {{.IncludePackageName}}

import (
	"context"
	"fmt"
	"strings"

{{- if or .UsesResourcesTypes $includePkg -}}
{{ "\n" }}
{{- end -}}
    "github.com/localrivet/buildsql"
{{- if $includePkg }}
    "{{.FullPackageName}}"
{{- end }}
	"{{.BaseImportPath}}/types"
	"github.com/jmoiron/sqlx"  
)

var _ {{.ModelName}}Model = (*custom{{.ModelName}}Model)(nil)

type (
    // {{.ModelName}}Model is an interface to be customized. Add more methods here,
    // and implement the added methods in custom{{.ModelName}}Model.
    {{.ModelName}}Model interface {
        {{FirstToLower .ModelName}}Model
				WithTx(tx Transactions) {{.ModelName}}Model
				FindAll(ctx context.Context, page int, pageSize int) ([]*{{$originalPkg}}.{{.ModelName}}, error)
				Search(ctx context.Context, currentPage, pageSize int64, filter string) (res *Search{{.ModelName}}Response, err error)
    }

    custom{{.ModelName}}Model struct {
        *default{{.ModelName}}Model
    }
)

// New{{.ModelName}}Model returns a model for the database table.
func New{{.ModelName}}Model(db *sqlx.DB) {{.ModelName}}Model {
    return &custom{{.ModelName}}Model{
        default{{.ModelName}}Model: new{{.ModelName}}Model(db),
    }
}

// WithTx returns a new instance of the *custom{{.ModelName}}Model that uses the provided transaction.
func (m *custom{{.ModelName}}Model) WithTx(tx Transactions) {{.ModelName}}Model {
	m.default{{.ModelName}}Model.transaction.tx = tx.GetTX()
	return m
}

func (m *custom{{.ModelName}}Model) FindAll(ctx context.Context, page int, pageSize int) ([]*{{$originalPkg}}.{{.ModelName}}, error) {
    var query string
    if pageSize == 0{
        query = fmt.Sprintf({{WrapInBackticks "SELECT %s FROM %s"}}, {{.ModelName}}Rows, m.table)
    } else {
        offset := (page - 1) * pageSize
        query = fmt.Sprintf({{WrapInBackticks "SELECT %s FROM %s LIMIT %d OFFSET %d"}}, {{.ModelName}}Rows, m.table, pageSize, offset)
    }

    var results []*{{$originalPkg}}.{{.ModelName}}
    err := m.transaction.db.SelectContext(ctx, &results, query)
    if err != nil {
        return nil, err
    }
    return results, nil
}

// response type
type Search{{.ModelName}}Response struct {
	{{.ModelName}}s []xo.{{.ModelName}}
	PagingStats    types.PagingStats
}

func (m *custom{{.ModelName}}Model) Search(ctx context.Context, currentPage, pageSize int64, filter string) (res *Search{{.ModelName}}Response, err error) {
	var builder = buildsql.NewQueryBuilder()
	where, orderBy, namedParamMap, err := builder.Build(filter, map[string]interface{}{
		"t1": xo.{{.ModelName}}{},
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
	for _, fieldName := range {{.ModelName}}FieldNames {
		fieldNames = append(fieldNames, fmt.Sprintf("t1.%s as \"%s.%s\"", fieldName, m.table, fieldName))
	}

	// fmt.Println("fieldNames:", fieldNames)
	// fmt.Println("tableNameNoTicks:", m.table)

	sql := fmt.Sprintf({{InsertBacktick}}
		SELECT
			-- {{RawTableName .TableName}}
			%s,
			-- stats
			COUNT(*) OVER() AS \"pagingstats.total_records\"
		FROM {{RawTableName .TableName}} t1
		%s
		%s
		%s
	{{InsertBacktick}}, strings.Join(fieldNames, ", "), where, orderBy, limit)


	// fmt.Println("sql:", sql)
	// fmt.Println("where:", where)
	// fmt.Println("order by:", orderBy)
	// fmt.Println("limit:", limit)

	var nstmt *sqlx.NamedStmt
	if m.transaction.isTx() {
		nstmt, err = m.transaction.tx.PrepareNamedContext(ctx, sql)
	} else {
		nstmt, err = m.transaction.db.PrepareNamedContext(ctx, sql)
	}
	if err != nil {
		return nil, fmt.Errorf("error::Search::Prepared::%s", err.Error())
	}

	var result []struct {
		{{.ModelName}} xo.{{.ModelName}}    {{InsertBacktick}}db:"{{RawTableName .TableName}}"{{InsertBacktick}}
		PagingStats   types.PagingStats  {{InsertBacktick}}db:"pagingstats"{{InsertBacktick}}
	}

	namedParamMap["offset"] = currentPage * pageSize
	namedParamMap["limit"] = pageSize

	err = nstmt.Select(&result, namedParamMap)
	if err != nil {
		return nil, fmt.Errorf("error::Search::Select::%s", err.Error())
	}

	records := []xo.{{.ModelName}}{}

	var stats *types.PagingStats = &types.PagingStats{}
	for i, r := range result {
		if i == 0 {
			stats = r.PagingStats.Calc(pageSize)
		}
		records = append(records, r.{{.ModelName}})
	}

	out := &Search{{.ModelName}}Response{
		{{.ModelName}}s: records,
		PagingStats:    *stats,
	}

	return out, err
}


`
