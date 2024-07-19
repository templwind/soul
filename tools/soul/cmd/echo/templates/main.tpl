package main

import (
	"flag"
	"fmt"
	"net/http"

	{{.importPackages}}
)

var configFile = flag.String("f", "etc/{{.serviceName}}.yaml", "the config file")

func main() {
	flag.Parse()

	// Load the configuration file
	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv())

	// Create a new service context
	svcCtx := svc.NewServiceContext(&c)

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
	

	// Start the server
	fmt.Printf("Starting server at %s:%d ...\n", c.Host, c.Port)
	server.Start()
}