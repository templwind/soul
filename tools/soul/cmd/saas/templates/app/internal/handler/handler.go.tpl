package {{.PkgName}}

import (
	{{.Imports}}
)

{{ if .HasSocket }}
{{ template "handler/socket-header" . }}
{{ end }}


{{/* -------------------------------- */}}
{{/* Loop over the methods  */}}
{{/* -------------------------------- */}}
{{- range .Methods}}
	{{if .HasDoc}}
		{{.Doc}}
	{{end}}

	{{if false }}
	// Detailed Review Against Standards

	// | **Method** | **Query Params** | **Request Body**           | **Common Response Types**                      | **Standards/Notes**                                                                   |
	// |------------|------------------|----------------------------|-----------------------------------------------|---------------------------------------------------------------------------------------|
	// | **GET**    | ✅ Frequently     | ❌ Not used                | `HTML`, `JSON`, `XML`, `Plain Text`           | Defined in RFC 7231 as safe and idempotent. Query params are the standard way to pass parameters. |
	// | **POST**   | ✅ Rarely         | ✅ Frequently              | `JSON`, `HTML`, `Plain Text`, `204 No Content`| Used for non-idempotent actions (e.g., creating resources). The body is required for data submission. |
	// | **PUT**    | ✅ Rarely         | ✅ Frequently (Full Data)  | `JSON`, `204 No Content`, `HTML`              | Defined in RFC 7231 for replacing resources. Query params may modify the operation but are uncommon. |
	// | **PATCH**  | ✅ Rarely         | ✅ Frequently (Partial Data)| `JSON`, `204 No Content`, `Plain Text`        | Standardized in RFC 5789. Designed for partial updates. Query params are rare.                      |
	// | **DELETE** | ✅ Sometimes      | ❌ Rarely                  | `204 No Content`, `JSON`, `Plain Text`        | Defined in RFC 7231 for deleting resources. Query params may define conditions like `softDelete`.  |

	// Method:           {{if .MethodRawName}}{{ .MethodRawName }}{{else}}N/A{{end}}
	// HasRequestType:   {{if .HasRequestType}}true{{else}}false{{end}} 
	// HasResponseType:  {{if .HasResponseType}}true{{else}}false{{end}}
	// HasPage:          {{if .HasPage}}true{{else}}false{{end}}     
	// HasBaseProps:     {{if .HasBaseProps}}true{{else}}false{{end}}   
	// ReturnsPartial:   {{if .ReturnsPartial}}true{{else}}false{{end}} 
	// ReturnsJson:      {{if .ReturnsJson}}true{{else}}false{{end}}    
	// ReturnsPlainText: {{if .ReturnsPlainText}}true{{else}}false{{end}}
	// ReturnsNoOutput:  {{if .ReturnsNoOutput}}true{{else}}false{{end}}   
	// ReturnsRedirect:  {{if .ReturnsRedirect}}true{{else}}false{{end}}
	// IsStatic:         {{if .IsStatic}}true{{else}}false{{end}}       
	// IsSocket:         {{if .IsSocket}}true{{else}}false{{end}}       
	// IsSSE:            {{if .IsSSE}}true{{else}}false{{end}}          
	// IsVideoStream:    {{if .IsVideoStream}}true{{else}}false{{end}}  
	// IsAudioStream:    {{if .IsAudioStream}}true{{else}}false{{end}}  
	// IsFullHTMLPage:   {{if .IsFullHTMLPage}}true{{else}}false{{end}} 
	// IsPubSub:         {{if .IsPubSub}}true{{else}}false{{end}}     
	// IsDownload:       {{if .IsDownload}}true{{else}}false{{end}}   
	{{ end }}   
	

	{{- if .IsPubSub }}
		{{ template "handler/pubsub" . }}
	{{ else }}
	func {{.HandlerName}}(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
		return func(c echo.Context) error {
		{{- if eq .MethodRawName "GET" -}}
			{{ template "handler/get" . -}}
		{{ else if eq .MethodRawName "POST" -}}
			{{ template "handler/post" . -}}
		{{ else if eq .MethodRawName "PUT" -}}
			{{ template "handler/put" . -}}
		{{ else if eq .MethodRawName "PATCH" -}}
			{{ template "handler/patch" . -}}
		{{ else if eq .MethodRawName "DELETE" -}}
			{{ template "handler/delete" . -}}
		{{end -}}
		}
	}
	{{ end -}}
{{ end -}}

{{/*
--------------------------------
Socket Header
--------------------------------
*/}}
{{ define "handler/socket-header" }}
// Socket header implementation
var Manager = wsmanager.NewConnectionManager()
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

{{/*
--------------------------------
PubSub Handler
--------------------------------
*/}}
{{ define "handler/pubsub" }}
	{{- template "pubsub-request-block" . -}}
{{ end }}

{{/*
--------------------------------
GET Handler
| **Method** | **Query Params** | **Request Body**           | **Common Response Types**                      | **Standards/Notes**                                                                   |
|------------|------------------|----------------------------|-----------------------------------------------|---------------------------------------------------------------------------------------|
| **GET**    | ✅ Frequently     | ❌ Not used                | `HTML`, `JSON`, `XML`, `Plain Text`           | Defined in RFC 7231 as safe and idempotent. Query params are the standard way to pass parameters. |
--------------------------------
*/}}
{{ define "handler/get" }}
	{{- if .IsSSE -}}
		{{- template "sse-request-block" . -}}
	{{- else if .IsSocket -}}
		{{- template "socket-request-block" . -}}
	{{- else -}}
		{{- template "request-block" . -}}
		{{- template "logic-instance" . -}}
		{{- template "html-response-block" . -}}
		{{- template "json-response-block" . -}}
		{{- template "plain-text-response-block" . -}}
		{{- template "no-response-block" . -}}
	{{- end -}}
{{ end }}

{{/*
--------------------------------
POST Handler
--------------------------------
*/}}
{{ define "handler/post" }}
	{{- template "request-block" . -}}
	{{- template "logic-instance" . -}}
	{{- template "html-response-block" . -}}
	{{- template "json-response-block" . -}}
	{{- template "plain-text-response-block" . -}}
	{{- template "no-response-block" . -}}
{{ end }}

{{/*
--------------------------------
PUT Handler
--------------------------------
*/}}
{{ define "handler/put" }}
	{{- template "request-block" . -}}
	{{- template "logic-instance" . -}}
	{{- template "html-response-block" . -}}
	{{- template "json-response-block" . -}}
	{{- template "plain-text-response-block" . -}}
	{{- template "no-response-block" . -}}
{{ end }}

{{/*
--------------------------------
PATCH Handler
--------------------------------
*/}}
{{ define "handler/patch" }}
	{{- template "request-block" . -}}
	{{- template "logic-instance" . -}}
	{{- template "html-response-block" . -}}
	{{- template "json-response-block" . -}}
	{{- template "plain-text-response-block" . -}}
	{{- template "no-response-block" . -}}
{{ end }}

{{/*
--------------------------------
DELETE Handler
--------------------------------
*/}}
{{ define "handler/delete" }}
	{{- template "request-block" . -}}
	{{- template "logic-instance" . -}}
	{{- template "html-response-block" . -}}
	{{- template "json-response-block" . -}}
	{{- template "plain-text-response-block" . -}}
	{{- template "no-response-block" . -}}
{{ end }}

{{/*
--------------------------------
Request Block
--------------------------------
*/}}
{{ define "request-block" }}
	{{- if .HasRequestType -}}
		var req {{if .HasPointerRequest}}*{{end}}{{if .HasArrayRequest}}[]{{end}}types.{{.RequestType}}
		if err := httpx.Parse(c, &req, path); err != nil {
			{{- template "error-response-block" . -}}
		}
	{{ end -}}
{{ end }}

{{/*
--------------------------------
Response Block
--------------------------------
*/}}
{{ define "response-block" }}
	{{- if .HasResponseType }}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
	{{- else if .IsFullHTMLPage }}
		baseProps := []soul.OptFunc[baseof.Props]{}
		{{- if .IsDownload }}
		_, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- else }}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}}, &baseProps)
		{{- end -}}
	{{- else if .ReturnsPartial }}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
	{{- else if .ReturnsRedirect }}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
	{{- else if .ReturnsPlainText }}
		resp, err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
	{{- else if .ReturnsNoOutput }}
		err := l.{{.LogicFunc}}(c{{if .HasRequestType}}, &req{{end}})
	{{- end }}
{{ end }}

{{/*
--------------------------------
Error Response Block
--------------------------------
*/}}
{{ define "error-response-block" }}
	c.Logger().Error(err)
	{{- if .ReturnsNoOutput }}
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	{{- else if .ReturnsPlainText }}
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	{{- else }}
		{{- if .HasResponseType }}
				return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		{{- else }}
			return soul.Render(c, http.StatusOK,
				error5x.New(
				error5x.WithErrors(
						"Internal Server Error",
						err.Error(),
					),
				),
			)
		{{- end }}
	{{- end }}
{{ end }}

{{/*
--------------------------------
Logic Instance
--------------------------------
*/}}
{{ define "logic-instance"}}
	{{- if .RequiresSocket -}}
		{{- if .IsSocket -}}
		// Extract user ID from context
		user := session.UserFromContext(c)
		if user == nil {
			return echo.ErrUnauthorized
		}
		userID := user.ID
		
		// Upgrade the HTTP connection to a WebSocket connection
		conn, _, _, err := gobwasWs.UpgradeHTTP(c.Request(), c.Response())
		if err != nil {
			return err
		}
		connection := wsmanager.NewConnection(conn)
		Manager.AddClient(connection, userID)
		defer Manager.RemoveClient(connection, userID)
		defer conn.Close()

		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, conn, c)
		{{- else -}}
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, nil, c)
		{{- end -}}
	{{- else -}}
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx)
	{{- end -}}
{{ end }} 

{{/*
--------------------------------
Full HTML Page
--------------------------------
*/}}
{{ define "html-response-block" }}
	{{- if or .IsFullHTMLPage .ReturnsPartial .ReturnsRedirect }}
		{{- template "response-block" . -}}
		if err != nil {
			{{- template "error-response-block" . -}}
		}
		if resp != nil {
		{{- if not .IsDownload }}
			if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) && !htmx.IsHtmxHistoryRestoreRequest(c.Request()) {
				return soul.Render(c, http.StatusOK,
					resp,
				)
			}
			{{- if or .ReturnsPartial }}
			return soul.Render(c, http.StatusOK, resp)
			{{- else }}
			return soul.Render(c, http.StatusOK,
				{{- if .HasBaseProps}}
				baseof.New(
					append(pageLayout.Layout(c, svcCtx, resp), baseProps...)...,
				),
				{{- else}}
				baseof.New(
					pageLayout.Layout(c, svcCtx, resp)...,
				),
				{{- end}}
			)
			{{- end }}
		}
		return nil
		{{- end }}
	{{- end }}
{{- end }}

{{/*
--------------------------------
Plain Text Response Block
--------------------------------
*/}}
{{ define "plain-text-response-block" }}
	{{- if .ReturnsPlainText }}
		{{- template "response-block" . -}}
		if err != nil {
			{{- template "error-response-block" . -}}
		}
		return c.String(http.StatusOK, resp)
	{{- end }}
{{ end }}

{{/*
--------------------------------
JSON Handler
--------------------------------
*/}}
{{ define "json-response-block" }}
	{{- if .ReturnsJson -}}
		{{- template "response-block" . -}}
		if err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		return c.JSON(http.StatusOK, resp)
	{{- end }}
{{- end}}

{{/*
--------------------------------
NO RESPONSE Handler
--------------------------------
*/}}
{{ define "no-response-block" }}
	{{- if .ReturnsNoOutput -}}
		{{- template "response-block" . -}}
		if err != nil {
			c.Logger().Error(err)
			return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
		}
		return c.NoContent(http.StatusOK)
	{{- end }}
{{- end}}

{{/*
--------------------------------
SSE
--------------------------------
*/}}
{{ define "sse-request-block" }}
		// Define SSEEvent locally
		type SSEEvent struct {
			ID     string      `json:"id"`
			Status string      `json:"status"`
			Time   time.Time   `json:"time"`
			Path   string      `json:"path"`
			Data   interface{} `json:"data,omitempty"`
		}

		// Extract user from the session context
		user := session.UserFromContext(c)
		if user == nil {
			return c.JSON(http.StatusUnauthorized, map[string]interface{}{
				"error": "Unauthorized",
			})
		}

		// Set SSE headers
		c.Response().Header().Set("Content-Type", "text/event-stream")
		c.Response().Header().Set("Cache-Control", "no-cache")
		c.Response().Header().Set("Connection", "keep-alive")
		c.Response().WriteHeader(http.StatusOK)

		// Ensure Flusher is supported
		flusher, ok := c.Response().Writer.(http.Flusher)
		if !ok {
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Streaming not supported",
			})
		}

		// Subscribe client to EventHub using both path and clientID
		eventChan := svcCtx.EventHub.Subscribe(path, user.ID)
		defer func() {
			svcCtx.EventHub.Unsubscribe(path, user.ID)
			c.Logger().Infof("Client %d unsubscribed from path %s", user.ID, path)
		}()

		// Send initial connection event
		initialEvent := SSEEvent{
			ID:     uuid.New().String(),
			Status: "connected",
			Time:   time.Now(),
			Path:   path,
		}
		jsonData, _ := json.Marshal(initialEvent)
		if _, err := c.Response().Writer.Write([]byte(fmt.Sprintf("data: %s\n\n", jsonData))); err != nil {
			c.Logger().Errorf("Failed to send initial event for client %d on path %s: %v", user.ID, path, err)
			return err
		}
		flusher.Flush()

		// Mutex for safe writes
		var writeMutex sync.Mutex

		// Goroutine to handle event sending
		ctx := c.Request().Context()
		go func() {
			for {
				select {
				case <-ctx.Done():
					return
				case event := <-eventChan:
					jsonData, err := json.Marshal(event)
					if err != nil {
						c.Logger().Errorf("Failed to marshal event for client %d on path %s: %v", user.ID, path, err)
						continue
					}

					writeMutex.Lock()
					_, err = c.Response().Writer.Write([]byte(fmt.Sprintf("data: %s\n\n", jsonData)))
					flusher.Flush()
					writeMutex.Unlock()

					if err != nil {
						c.Logger().Errorf("Failed to send event for client %d on path %s: %v", user.ID, path, err)
						return
					}
				}
			}
		}()

		// Keep connection alive with heartbeats
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				// Client disconnected
				return nil
			case <-ticker.C:
				writeMutex.Lock()
				if _, err := c.Response().Writer.Write([]byte(": keepalive\n\n")); err != nil {
					writeMutex.Unlock()
					c.Logger().Errorf("Failed to send heartbeat for client %d on path %s: %v", user.ID, path, err)
					return err
				}
				flusher.Flush()
				writeMutex.Unlock()
			}
		}
{{ end }}


{{/*
--------------------------------
PubSub
--------------------------------
*/}}
{{ define "pubsub-request-block" }}
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
		var req {{if .HasPointerRequest}}*{{end}}{{if .HasArrayRequest}}[]{{end}}types.{{.PubSubTopic.RequestType}}
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
{{ end }}


{{ define "socket-request-block" }}
	// Extract user ID from context
	user := session.UserFromContext(c)
	if user == nil {
		return echo.ErrUnauthorized
	}
	userID := user.ID

	// Upgrade the HTTP connection to a WebSocket connection
	conn, _, _, err := gobwasWs.UpgradeHTTP(c.Request(), c.Response())
	if err != nil {
		return err
	}
	connection := wsmanager.NewConnection(conn)
	Manager.AddClient(connection, userID)
	defer Manager.RemoveClient(connection, userID)
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
					var req {{if .HasPointerRequest}}*{{end}}{{if .HasArrayRequest}}[]{{end}}types.{{.RequestType}}
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
				Manager.Subscribe(connection, topicMsg.Topic)
			case "broadcast":
				Manager.Broadcast(msg, connection)
			default:
				log.Printf("Unknown message: %s", data)
			}
		}
	}
	return nil
{{- end}}