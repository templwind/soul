package {{.pkgName}}

import (
	{{ .imports }}
)

{{- if false }}
// HasRequestType:  {{if .HasRequestType}}true{{else}}false{{end}} 
// HasResponseType: {{if .HasResponseType}}true{{else}}false{{end}}
// HasPage:         {{if .HasPage}}true{{else}}false{{end}}        
// ReturnsPartial:  {{if .ReturnsPartial}}true{{else}}false{{end}} 
// ReturnsJson:     {{if .ReturnsJson}}true{{else}}false{{end}}    
// IsStatic:        {{if .IsStatic}}true{{else}}false{{end}}       
// IsSocket:        {{if .IsSocket}}true{{else}}false{{end}}       
// IsSSE:           {{if .IsSSE}}true{{else}}false{{end}}          
// IsVideoStream:   {{if .IsVideoStream}}true{{else}}false{{end}}  
// IsAudioStream:   {{if .IsAudioStream}}true{{else}}false{{end}}  
// IsFullHTMLPage:  {{if .IsFullHTMLPage}}true{{else}}false{{end}} 
// NoOutput:        {{if .NoOutput}}true{{else}}false{{end}}      
{{- end}}

type {{.LogicType}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
	{{- if .hasSocket}}
	conn   net.Conn
	echoCtx echo.Context
	{{end -}}
}

func New{{.LogicType}}(ctx context.Context, svcCtx *svc.ServiceContext{{if .hasSocket}}, conn net.Conn, echoCtx echo.Context{{end}}) *{{.LogicType}} {
	return &{{.LogicType}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
		{{- if .hasSocket}}
		conn:   conn,
		echoCtx: echoCtx,
		{{end -}}
	}
}
{{range .methods}}
{{- if .HasDoc}}
{{.Doc}}
{{- end}}
{{- if .IsSocket}}
func {{ if .Topic.InitiatedByClient -}}(l *{{.LogicType}}) {{end}}{{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
{{else}}
func (l *{{.LogicType}}) {{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
{{- end}}
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
	{{- if .HasBaseProps}}
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