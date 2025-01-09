package {{.pkgName}}

import (
	{{ .imports }}
)

type {{.LogicType}} struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
	{{- if .hasSocket }}
	conn   net.Conn
	echoCtx echo.Context
	manager *wsmanager.ConnectionManager
	{{ end }}
}

func New{{.LogicType}}(ctx context.Context, svcCtx *svc.ServiceContext{{if .hasSocket}}, conn net.Conn, echoCtx echo.Context, manager *wsmanager.ConnectionManager{{end}}) *{{.LogicType}} {
	return &{{.LogicType}}{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
		{{- if .hasSocket }}
		conn:   conn,
		echoCtx: echoCtx,
		manager: manager,
		{{- end }}
	}
}
{{range .methods }}
	{{- if false }}
	// Detailed Review Against Standards

	// | **Method** | **Query Params** | **Request Body**           | **Common Response Types**                      | **Standards/Notes**                                                                   |
	// |------------|------------------|----------------------------|-----------------------------------------------|---------------------------------------------------------------------------------------|
	// | **GET**    | ✅ Frequently     | ❌ Not used                | `HTML`, `JSON`, `XML`, `Plain Text`           | Defined in RFC 7231 as safe and idempotent. Query params are the standard way to pass parameters. |
	// | **POST**   | ✅ Rarely         | ✅ Frequently              | `JSON`, `HTML`, `Plain Text`, `204 No Content`| Used for non-idempotent actions (e.g., creating resources). The body is required for data submission. |
	// | **PUT**    | ✅ Rarely         | ✅ Frequently (Full Data)  | `JSON`, `204 No Content`, `HTML`              | Defined in RFC 7231 for replacing resources. Query params may modify the operation but are uncommon. |
	// | **PATCH**  | ✅ Rarely         | ✅ Frequently (Partial Data)| `JSON`, `204 No Content`, `Plain Text`        | Standardized in RFC 5789. Designed for partial updates. Query params are rare.                      |
	// | **DELETE** | ✅ Sometimes      | ❌ Rarely                  | `204 No Content`, `JSON`, `Plain Text`        | Defined in RFC 7231 for deleting resources. Query params may define conditions like `softDelete`.  |

	// Method:          {{if .MethodRawName}}{{ .MethodRawName }}{{else}}N/A{{end}}
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
	// IsPubSub:        {{if .IsPubSub}}true{{else}}false{{end}}     
	// IsDownload:      {{if .IsDownload}}true{{else}}false{{end}}   
	{{- end }}
	{{- if .IsSocket }}
		// socket logic {{ if .Topic.InitiatedByClient -}} client initiated {{ else -}} server initiated {{ end }}
	{{- end }}
	{{- if .ReturnsFullHTML }}
		// full html page logic
	{{- end }}
	{{- if .ReturnsPartial }}
		// partial logic
	{{- end }}

	{{- if .HasDoc }}
		{{ .Doc }}
	{{- end }}
	
	{{- if not .IsSocket }}
	func (l *{{.LogicType}}) {{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
		// todo: add your logic here and delete this line
		
		{{- if .HasBaseProps}}
		// todo: uncomment to add your base template properties
		// note: updated your template include path to use the correct theme
		
		// *baseProps = append(*baseProps,
			// baseof.WithHeader(nil),
			// baseof.WithFooter(nil),
		// )
		{{end}}

		{{.ReturnString}}
	}
	{{ else }}
		{{ if .Topic.InitiatedByClient -}}
		func (l *{{.LogicType}}) {{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
			// shortcut for server initiated events
			// send the response to the client via the events engine
			events.Next(types.{{.Topic.Const}}, req)

			{{.ReturnString}}
		}
		{{ else }}
		func (l *{{.LogicType}}) {{.LogicFunc}}({{.Request}}) {{.ResponseType}} {
			// todo: add your logic here and delete this line
			events.Next(types.{{.Topic.Const}}, req)
			{{.ReturnString}}
		}
		{{ end -}}
	{{end -}}
{{end}}