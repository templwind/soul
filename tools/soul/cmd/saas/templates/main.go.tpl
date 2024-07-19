package main

import (
	{{.imports}}
)

var configFile = flag.String("f", "etc/{{.serviceName}}.yaml", "the config file")

func main() {
	flag.Parse()

	// Load the configuration file
	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv())

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

	// Add static file serving
	server.Echo.Static("/assets", "assets")
	server.Echo.Static("/static", "static")
	

	// Start the server
	fmt.Printf("Starting server at %s:%d ...\n", c.Host, c.Port)
	server.Start()
}