package main

import (
	{{.imports}}
)

//go:embed static
var staticFS embed.FS

//go:embed assets
var assetsFS embed.FS

//go:embed etc/*.yaml
var configFS embed.FS

var configFile = flag.String("f", "etc/{{.serviceName}}.yaml", "the config file")

func main() {
	flag.Parse()

	// Load the configuration file
	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv(), conf.UseFS(configFS))

	// add the static logo to the config
	// logo, err := staticFS.ReadFile("static/images/logo.svg")
	// if err != nil {
	// 	panic(err)
	// }
	// c.Site.LogoSvg = string(logo)


	// Create a new service context
	svcCtx := svc.NewServiceContext(&c)

	{{ if .hasWorkflow -}}
	// start the temporal STT service and workers
	svcCtx.SetWorkflowService(
		stt.NewWorkFlowService(&c, svcCtx.DB).
			StartSubscribers().
			StartWorkers(3),
	)
	defer svcCtx.WorkflowService.Close()
	{{- end}}

	// Create a new server
	server := webserver.MustNewServer(
		c.WebServerConf,
		webserver.WithMiddleware(middleware.Recover()),
	)
	defer server.Stop()

	// Register the handlers
	handler.RegisterHandlers(server.Echo, svcCtx)

	// remove trailing slash
	server.Echo.Use(middleware.RemoveTrailingSlashWithConfig(middleware.TrailingSlashConfig{
		RedirectCode: http.StatusMovedPermanently,
	}))

	// CORS middleware
	server.Echo.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{
			"http://domain.com",
			"https://domain.com",
			"http://local.domain.com:8888",
			"http://localhost:8888",
			"http://localhost:3000",
		}, // Allow all origins
		AllowMethods:     []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete, http.MethodPatch, http.MethodOptions}, // Allow specific methods
		AllowHeaders:     []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept},                                             // Allow specific headers
		AllowCredentials: true,                                                                                                               // Allow credentials
	}))

	// Add static file serving
	assetsGroup := server.Echo.Group("/assets", svcCtx.NoCache)
	assetsSubFS := echo.MustSubFS(assetsFS, "assets")
	assetsGroup.StaticFS("/", assetsSubFS)
	staticSubFS := echo.MustSubFS(staticFS, "static")
	server.Echo.StaticFS("/static", staticSubFS)

	// Start the server
	fmt.Printf("Starting server at %s:%d ...\n", c.Host, c.Port)
	server.Start()
}