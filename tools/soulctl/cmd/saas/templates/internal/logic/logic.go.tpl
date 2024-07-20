package {{.pkgName}}

import (
	{{ .imports }}
)

type {{.LogicType}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext{{if .hasSocket}}
	conn   net.Conn
	echoCtx echo.Context
	{{end -}}
}

func New{{.LogicType}}(ctx context.Context, svcCtx *svc.ServiceContext{{if .hasSocket}}, conn net.Conn, echoCtx echo.Context{{end}}) *{{.LogicType}} {
	return &{{.LogicType}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,{{if .hasSocket}}
		conn:   conn,
		echoCtx: echoCtx,
		{{end -}}
		svcCtx: svcCtx,
	}
}

{{- range .methods}}
{{if .HasDoc}}{{.Doc}}{{end}}
{{- if .IsSocket}}
func {{.Call}}({{.Request}}) {{.ResponseType}} {
{{else}}
func (l *{{.LogicType}}) {{.Call}}({{.Request}}) {{.ResponseType}} {
{{end}}
	{{- if .IsSocket -}}
	{{- if .Topic.InitiatedByServer -}}
	// shortcut for server initiated events
	// send the response to the client via the events engine
	events.Next(types.{{.Topic.Const}}, req)
	{{- else -}}
	// todo: add your logic here and delete this line

	return
	{{end -}}
	{{else}}
	{{- if not .ReturnsPartial}}
	// todo: uncomment to add your base template properties
	// note: updated your template include path to use the correct theme
	
	// *baseProps = append(*baseProps,
		// baseof.WithHeader(nil),
		// baseof.WithFooter(nil),
	// )
	{{end}}
	// todo: add your logic here and delete this line

	{{.ReturnString}}
	{{end -}}
}
{{end}}