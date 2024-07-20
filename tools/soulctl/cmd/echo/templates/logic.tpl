package {{.PkgName}}

import (
	{{.Imports}}
)

type {{.LogicType}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext{{if .HasSocket}}
	conn   net.Conn
	{{end -}}
}

func New{{.LogicType}}(ctx context.Context, svcCtx *svc.ServiceContext{{if .HasSocket}}, conn net.Conn{{end}}) *{{.LogicType}} {
	return &{{.LogicType}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,{{if .HasSocket}}
		conn:   conn,
		{{end -}}
		svcCtx: svcCtx,
	}
}

{{- range .Methods}}
{{if .HasDoc}}{{.Doc}}{{end}}
func (l *{{.LogicType}}) {{.Call}}({{.Request}}) {{.ResponseType}} {
	{{- if .IsSocket}}
	// todo: add your logic here and delete this line
	{{- if .Topic.InitiatedByServer}}
	resp := {{.Topic.ResponseType}}{}

	// send the response to the client via the events engine
	events.Next(types.{{.Topic.Const}}, resp)
	{{else}}
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