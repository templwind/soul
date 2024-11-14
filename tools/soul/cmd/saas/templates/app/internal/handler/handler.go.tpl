package {{.PkgName}}

import (
	{{.Imports}}
)

{{ if .HasSocket }}
var manager = wsmanager.NewConnectionManager()
var subscriptions = make(map[string]events.Subscription)
var subscriptionMutex sync.RWMutex

func init() {
	// Initialize subscriptions for known topics
	{{ range .SocketServerTopics }}
		// Subscribe to {{.}} event
		addSubscription(types.{{.}})
	{{ end}}
}

func addSubscription(topic string) {
	subscriptionMutex.Lock()
	defer subscriptionMutex.Unlock()

	if _, exists := subscriptions[topic]; !exists {
		subscriptions[topic] = events.Subscribe(topic, func(ctx context.Context, resp any, connection net.Conn) error {
			payload, err := json.Marshal(resp)
			if err != nil {
				return err
			}

			var msg wsmanager.Message
			msg.Topic = topic
			msg.Payload = json.RawMessage(payload)
			msg.ID = uuid.New().String()

			out, err := json.Marshal(msg)
			if err != nil {
				return err
			}

			return wsutil.WriteServerMessage(connection, gobwasWs.OpText, out)
		})
	}
}
{{ end }}


{{- range .Methods}}
{{if .HasDoc}}
	{{.Doc}}
{{end}}

{{if false }}
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
{{ end }}    

{{- if .IsPubSub }}
func {{.HandlerName}}(svcCtx *svc.ServiceContext, topic, group string) {
	// subscribe to the topic
	log.Printf("Subscribing to topic %s", topic)

	var err error

	// Create the stream if it doesn't exist
	err = svcCtx.PubSubBroker.CreateStream(group, topic, 1*time.Minute)
	if err != nil {
		log.Printf("Failed to create stream for topic %s: %v", topic, err)
		// Note: We continue even if stream creation fails, as it might already exist
	}

	err = svcCtx.PubSubBroker.Subscribe(topic, group, func(msg []byte) ([]byte, error) {
		var req types.{{.PubSubTopic.RequestType}}
		if err := json.Unmarshal(msg, &req); err != nil {
			log.Printf("Failed to unmarshal message: %v", err)
			return nil, err
		}

		ctx := context.Background()
		l := {{.LogicName}}.New{{.LogicType}}(ctx, svcCtx)
		{{ if .HasResponseType }}response, {{ end }}err := l.{{.LogicFunc}}(&req)
		if err != nil {
			log.Printf("Failed to process {{.PubSubTopic.RequestType}}: %v", err)
		}
		{{ if .HasResponseType }}
		// Marshal the response to send it back as the acknowledgment response
		responseData, err := json.Marshal(response)
		if err != nil {
			log.Printf("Failed to marshal response: %v", err)
			return nil, err
		}

		err = svcCtx.PubSubBroker.Publish("{{.PubSubTopic.ResponseTopic}}", responseData)
		if err != nil {
			log.Printf("Failed to publish response to topic %s: %v", "{{.PubSubTopic.ResponseTopic}}", err)
			return nil, err
		}
		log.Printf("Successfully published to topic %s", "{{.PubSubTopic.ResponseTopic}}")
		{{ end }}
		return []byte{}, nil
	})
	if err != nil {
		log.Printf("Failed to subscribe to topic %s: %v", topic, err)
	} else {
		log.Printf("Successfully subscribed to topic %s", topic)
	}
}
{{ else }}
func {{.HandlerName}}(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
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
{{ end -}}
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
		if err := httpx.Parse(c, &req, path); err != nil {
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
		baseProps := []soul.OptFunc[baseof.Props]{}
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
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
				return soul.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return soul.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(c, svcCtx)...,
				),
			)
			{{- end}}
		}
		{{- if .IsFullHTMLPage}}
		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
			return soul.Render(c, http.StatusOK,
				resp,
			)
		}
		return soul.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(c, svcCtx, resp), baseProps...)...,
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
		if err := httpx.Parse(c, &req, path); err != nil {
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
		baseProps := []soul.OptFunc[baseof.Props]{}
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
		if err := httpx.Parse(c, &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		
		{{ template "instance" . }}
		{{- if .IsFullHTMLPage}}
		baseProps := []soul.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- else}}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
		{{- end}}
		if err != nil {
			c.Logger().Error(err)
			{{- if .IsFullHTMLPage}}
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
				return soul.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return soul.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(c, svcCtx)...,
				),
			)
			{{- else}}
			return c.HTML(http.StatusOK, "Internal Server Error")
			{{- end}}
		}

		{{- if .IsFullHTMLPage}}
		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
			return soul.Render(c, http.StatusOK,
				resp,
			)
		}
		return soul.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(c, svcCtx, resp), baseProps...)...,
			),
			{{- else}}
			baseof.New(
				pageLayout.Layout(svcCtx, resp)...,
			),
			{{- end}}
		)
		{{- else}}
		if resp != nil {
			return soul.Render(c, http.StatusOK,
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
		if err := httpx.Parse(c, &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		{{end -}}
		{{ template "instance" . }}
		baseProps := []soul.OptFunc[baseof.Props]{}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		if err != nil {
			c.Logger().Error(err)
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
				return soul.Render(c, http.StatusOK,
					error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
							err.Error(),
						),
					),
				)
			}
			return soul.Render(c, http.StatusInternalServerError,
				baseof.New(
					pageLayout.Error5xLayout(c, svcCtx)...,
				),
			)
		}

		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
			return soul.Render(c, http.StatusOK,
				resp,
			)
		}
		return soul.Render(c, http.StatusOK,
			{{- if .HasBaseProps}}
			baseof.New(
				append(pageLayout.Layout(c, svcCtx, resp), baseProps...)...,
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
		if err := httpx.Parse(c, &req, path); err != nil {
			c.Logger().Error(err)
			return soul.Render(c, http.StatusOK,
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

		{{ if gt (len .TopicsFromClient) 0 }}
		// Create a new ws logic instance
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, conn, c)
		{{ end }}

		// Handle connect event
		if err := wsutil.WriteServerMessage(conn, gobwasWs.OpText, []byte("ok")); err != nil {
			c.Logger().Error(err)
			return err
		}

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

				// Create a new request with the payload as the body
				req, err := http.NewRequest("POST", path, bytes.NewReader(msg.Payload))
				if err != nil {
					return err
				}
				req.Header.Set("Content-Type", "application/json")

				{{ if gt (len .TopicsFromClient) 0 }}
				// Create a new echo.Context with the modified request
				echoCtx := echo.New().NewContext(req, nil)
				{{ end }}

				switch msg.Topic {
				{{range .TopicsFromClient}}
				case types.{{.Topic}}:
					go func() { 
						{{- if .HasReqType -}}
						var req types.{{.RequestType}}
						if err := httpx.Parse(echoCtx, &req, path); err != nil {
							c.Logger().Error(err)
						}
						echoCtx = nil
						{{end -}}
						if resp, err := l.{{.LogicFunc}}({{if .HasReqType}}&req{{end}}); err != nil {
							c.Logger().Error(err)
						} else {
							resp, err := json.Marshal(resp)
							if err != nil {
								c.Logger().Error(err)
							}

							if resp != nil {
								msg.Payload = json.RawMessage(resp)
								{{- if .ResponseTopic}}
								msg.Topic = types.{{.ResponseTopic}}
								{{- end}}
								
								responseMessage, err := json.Marshal(msg)
								if err != nil {
									c.Logger().Error(err)
								}

								if err := wsutil.WriteServerMessage(conn, gobwasWs.OpText, responseMessage); err != nil {
									c.Logger().Error(err)
								}
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
