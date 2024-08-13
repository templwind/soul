package {{.PkgName}}

import (
	{{.Imports}}
)

{{- range .Methods}}
{{if .HasDoc}}
	{{.Doc}}
{{end}}

{{if true }}
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
{{ end }}    

func {{.HandlerName}}(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
	{{if .IsSocket}}
	var manager = wsmanager.NewConnectionManager()
	{{end -}}

	return func(c echo.Context) error {
		{{- if .IsStatic -}}
			{{ template "static" . }}
		{{- else if .IsSocket -}}
			{{ template "socket" . }}
		{{- else if .IsSSE -}}
			{{ template "sse" . }}
		{{- else if .IsVideoStream -}}
			{{ template "video" . }}
		{{- else if .IsAudioStream -}}
			{{ template "audio" . }}
		{{- else if .ReturnsJson -}}
			{{ template "json" . }}
		{{- else if .ReturnsPartial -}}
			{{ template "partial" . }}
		{{- else if .IsFullHTMLPage -}}
			{{ template "fullHTML" . -}}
		{{- else}}
			{{ template "default" . -}}
		{{- end}}
	}
}

{{end -}}


{{ define "instance"}}
		{{- if .RequiresSocket}}
		{{ if .IsSocket}}
		// Upgrade the HTTP connection to a WebSocket connection
		conn, _, _, err := gobwasWs.UpgradeHTTP(c.Request(), c.Response())
		if err != nil {
			return err
		}
		connection := wsmanager.NewConnection(conn)
		manager.AddClient(connection)
		defer manager.RemoveClient(connection)
		defer conn.Close()

		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, conn, c)
		{{else}}
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, nil, c)
		{{end}}
		{{ else }}
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx)
		{{- end }}
{{ end }} 


{{ define "static"}}
		{{- if .HasRequestType -}}
		var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		{{ template "instance" . }}
		{{- if .HasResponseType}}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
		{{end}}
		{{- if .IsFullHTMLPage}}
		baseProps := []templwind.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- end}}
		if err != nil {
			c.Logger().Error(err)
			{{- if .ReturnsJson}}
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
			{{- end }}
			{{- if or (.IsFullHTMLPage) (.ReturnsPartial) }}
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
				return templwind.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return templwind.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(svcCtx)...,
				),
			)
			{{- end}}
		}
		{{- if .IsFullHTMLPage}}
		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
			return templwind.Render(c, http.StatusOK,
				resp,
			)
		}
		return templwind.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(svcCtx, resp), baseProps...)...,
			),
			{{- else}}
			baseof.New(
				pageLayout.Layout(svcCtx, resp)...,
			),
			{{- end}}
		)
		{{- end}}
{{- end}}
{{ define "sse" }}
		return nil
{{- end}}
{{ define "video" }}
		return nil
{{- end}}
{{ define "audio" }}
		return nil
{{- end}}
{{ define "json" }}
		{{- if .HasRequestType -}}
		var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		{{ template "instance" . }}
		{{- if .HasResponseType}}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
		{{- end}}
		{{- if .IsFullHTMLPage}}
		baseProps := []templwind.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- end}}
		if err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		return c.JSON(http.StatusOK, resp)
{{- end}}

{{ define "partial" }}
		{{- if .HasRequestType -}}
		var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		
		{{ template "instance" . }}
		{{- if .IsFullHTMLPage}}
		baseProps := []templwind.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- else}}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
		{{- end}}
		if err != nil {
			c.Logger().Error(err)
			{{- if .IsFullHTMLPage}}
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
				return templwind.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return templwind.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(svcCtx)...,
				),
			)
			{{- else}}
			return c.HTML(http.StatusOK, "Internal Server Error")
			{{- end}}
		}

		{{- if .IsFullHTMLPage}}
		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
			return templwind.Render(c, http.StatusOK,
				resp,
			)
		}
		return templwind.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(svcCtx, resp), baseProps...)...,
			),
			{{- else}}
			baseof.New(
				pageLayout.Layout(svcCtx, resp)...,
			),
			{{- end}}
		)
		{{- else}}
		if resp != nil {
			return templwind.Render(c, http.StatusOK,
				resp,
			)
		} else {
			return nil
		}
		{{- end}}
{{- end}}

{{ define "fullHTML" }}
		{{- if .HasRequestType -}}
		var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		{{ template "instance" . }}
		baseProps := []templwind.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		if err != nil {
			c.Logger().Error(err)
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
				return templwind.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return templwind.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(svcCtx)...,
				),
			)
		}

		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
			return templwind.Render(c, http.StatusOK,
				resp,
			)
		}
		return templwind.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(svcCtx, resp), baseProps...)...,
			),
			{{- else}}
			baseof.New(
				pageLayout.Layout(svcCtx, resp)...,
			),
			{{- end}}
		)
{{- end}}

{{ define "default" }}
		{{- if .HasRequestType -}}
		var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			c.Logger().Error(err)
			return templwind.Render(c, http.StatusOK,
				error5x.New(
					error5x.WithErrors(
						"Internal Server Error",
						err.Error(),
					),
				),
			)
		}
		{{- end}}
		{{ template "instance" .}}
		return l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
{{- end}}

{{ define "socket" }}
// Upgrade the HTTP connection to a WebSocket connection
		conn, _, _, err := gobwasWs.UpgradeHTTP(c.Request(), c.Response())
		if err != nil {
			return err
		}
		connection := wsmanager.NewConnection(conn)
		manager.AddClient(connection)
		defer manager.RemoveClient(connection)
		defer conn.Close()

		// Create a new ws logic instance
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, conn, c)

		// Handle connect event
		if err := wsutil.WriteServerMessage(conn, gobwasWs.OpText, []byte("ok")); err != nil {
			c.Logger().Error(err)
			return err
		}

		{{range .TopicsFromServer}}
		// Subscribe to {{.RawTopic}} event
		defer events.Unsubscribe(
			events.Subscribe(types.{{.Topic}}, func(ctx context.Context, resp any) error {
				payload, err := json.Marshal(resp)
				if err != nil {
					return err
				}

				var msg wsmanager.Message
				msg.Topic = types.{{.Topic}}
				msg.Payload = json.RawMessage(payload)
				msg.ID = uuid.New().String()

				out, err := json.Marshal(msg)
				if err != nil {
					return err
				}
				return wsutil.WriteServerMessage(conn, gobwasWs.OpText, out)
			}),
		)
		{{end}}

		// Handle incoming messages
		for {
			data, op, err := wsutil.ReadClientData(conn)
			if err != nil {
				c.Logger().Error(err)
				break
			}

			if op == gobwasWs.OpPing {
				if err := wsutil.WriteServerMessage(conn, gobwasWs.OpPong, nil); err != nil {
					c.Logger().Error(err)
					break
				}
				continue
			}

			// check for a raw text ping message
			if string(data) == "ping" {
				if err := wsutil.WriteServerMessage(conn, gobwasWs.OpText, []byte("pong")); err != nil {
					c.Logger().Error(err)
					break
				}
				continue
			}

			if op == gobwasWs.OpText {
				var msg wsmanager.Message
				if err := json.Unmarshal(data, &msg); err != nil {
					c.Logger().Error(err)
					break
				}

				switch msg.Topic {
				{{range .TopicsFromClient}}
				case types.{{.Topic}}:
					go func() { 
						{{- if .HasReqType -}}
						var req types.{{.RequestType}}
						if err := httpx.Parse(c.Request(), &req, path); err != nil {
							c.Logger().Error(err)
						}
						{{end -}}
						if resp, err := l.{{.LogicFunc}}({{if .HasReqType}}&req{{end}}); err != nil {
							c.Logger().Error(err)
						} else {
							resp, err := json.Marshal(resp)
							if err != nil {
								c.Logger().Error(err)
							}
							if err := wsutil.WriteServerMessage(conn, gobwasWs.OpText, resp); err != nil {
								c.Logger().Error(err)
							}
						}
					}()
				{{end}}
				case "subscribe":
					var topicMsg struct {
						Topic string `json:"topic"`
					}
					if err := json.Unmarshal(msg.Payload, &topicMsg); err != nil {
						c.Logger().Error(err)
						break
					}
					manager.Subscribe(connection, topicMsg.Topic)
				case "broadcast":
					manager.Broadcast(msg, connection)
				default:
					log.Printf("Unknown message: %s", data)
				}
			}
		}
		return nil
{{- end}}
