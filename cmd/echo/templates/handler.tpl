package {{.PkgName}}

import (
	{{.Imports}}
)

{{range .Methods}}
{{if .HasDoc}}{{.Doc}}{{end}}
func {{.HandlerName}}(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
	{{- if .IsSocket}}	
	type message struct {
		Topic   string
		Payload []byte
	}
	{{end -}}
	return func(c echo.Context) error {
		{{if .IsSocket}}// Upgrade the HTTP connection to a WebSocket connection
		conn, _, _, err := gobwasWs.UpgradeHTTP(c.Request(), c.Response())
		if err != nil {
			return err
		}
		defer conn.Close()

		// Create a new ws logic instance
		l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx, conn)

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
				msg := map[string]interface{}{
					types.{{.Topic}}: payload,
				}
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
			if op != gobwasWs.OpText {
				msg := message{}
				if err := json.Unmarshal(data, &msg); err != nil {
					c.Logger().Error(err)
					break
				}

				switch msg.Topic {
				{{range .TopicsFromClient}}
				case types.{{.Topic}}:
					go func() { {{if .HasReqType}}req := &types.{{.RequestType}}{}
						if err := json.Unmarshal(msg.Payload, req); err != nil {
							c.Logger().Error(err)
						}{{end}}
						if resp, err := l.{{.Call}}({{if .HasReqType}}req{{end}}); err != nil {
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
				default:
					log.Printf("Unknown message: %s", data)
				}
			}
		}
		return nil{{else}}
		{{- if .HasReq}}var req types.{{.RequestType}}
		if err := httpx.Parse(c.Request(), &req, path); err != nil {
			// Log the error and send a generic error message to the client
			c.Logger().Error(err)
			// Send a JSON error response
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		
		{{end}}l := {{.LogicName}}.New{{.LogicType}}(c.Request().Context(), svcCtx)
		{{- if not .ReturnsPartial}}
		{{if not .HasResp}}baseProps := []templwind.OptFunc[baseof.Props]{}{{end -}}
		{{end}}
		{{if .HasResp}}resp, {{else}}content, {{end}}err := l.{{.Call}}(c{{if .HasReq}}, &req{{end}}{{if not .ReturnsPartial}}{{if not .HasResp}}, &baseProps{{end}}{{end}})
		{{- if .ReturnsPartial}}
		if err != nil {
			// Log the error and send a generic error message to the client
			c.Logger().Error(err)
			return templwind.Render(c, http.StatusInternalServerError, error5x.New(
				error5x.WithErrors(
					"Internal Server Error",
					err.Error(),
				),
			))
		}

		if content != nil {
			return templwind.Render(c, http.StatusOK, content)
		} else {
			return nil
		}
		{{- else}}
		if err != nil {
			// Log the error and send a generic error message to the client
			c.Logger().Error(err)
			{{if .HasResp}}
			// Send a JSON error response
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			}){{else}}
			// intercept htmx requests and just return the error
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
			// Send an HTML error response
			return templwind.Render(c, http.StatusInternalServerError,
				baseof.New(
					baseof.WithLTRDir("ltr"),
					baseof.WithLangCode("en"),
					baseof.WithHead(head.New(
						head.WithSiteTitle(svcCtx.Config.Site.Title),
						head.WithIsHome(true),
						head.WithCSS(
							svcCtx.Config.Assets.{{.AssetGroup}}.CSS...,
						),
					)),
					baseof.WithContent(error5x.New(
						error5x.WithErrors(
							"Internal Server Error",
						),
					)),
				),
			){{end}}
		}
		{{if .HasResp}}
		return c.JSON(http.StatusOK, resp){{else}}// intercept htmx requests and just return the content
		if htmx.IsHtmxRequest(c.Request()) && !htmx.IsHtmxBoosted(c.Request()) {
			// Render the page with just the content
			return templwind.Render(c, http.StatusOK,
				content,
			)
		}
		loginUrl := "/auth/login"
		if menu, ok := svcCtx.Config.Menus["login"]; ok && len(menu) > 0 {
			loginUrl = menu[0].URL
		}
		// Assemble the page
		// Combine default properties and baseProps
		allProps := append([]templwind.OptFunc[baseof.Props]{
			baseof.WithLTRDir("ltr"),
			baseof.WithLangCode("en"),
			baseof.WithHead(head.New(
				head.WithSiteTitle(svcCtx.Config.Site.Title),
				head.WithIsHome(true),
				head.WithCSS(
					svcCtx.Config.Assets.{{.AssetGroup}}.CSS...,
				),
				head.WithJS(
					svcCtx.Config.Assets.{{.AssetGroup}}.JS...,
				),
			)),
			baseof.WithHeader(header.New(
				header.WithConfig(svcCtx.Config),
				header.WithBrandName(svcCtx.Config.Site.Title),
				header.WithLoginURL(loginUrl),
				header.WithLoginTitle("Log in"),
				header.WithMenus(svcCtx.Menus),
			)),
			baseof.WithMenus(svcCtx.Menus),
			baseof.WithFooter(footer.New(
				footer.WithConfig(svcCtx.Config),
				footer.WithMenus(svcCtx.Menus),
				footer.WithYear(strconv.Itoa(time.Now().Year())),
			)),
			baseof.WithContent(content),
		}, baseProps...)

		// Render the page with all properties
		return templwind.Render(c, http.StatusOK,
			baseof.New(allProps...),
		){{end}}{{end}}{{end}}
	}
}{{end}}
