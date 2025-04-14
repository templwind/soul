package main

import (
	"embed"
	"flag"
	"fmt"
	"net/http"

	"backend/internal/config"
	"backend/internal/handler"
	"backend/internal/svc"

	_ "github.com/joho/godotenv/autoload"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/templwind/soul/conf"
	"github.com/templwind/soul/webserver"
)

//go:embed etc/*.yaml
var configFS embed.FS

// the config file
var configFile = flag.String("f", "etc/backend.yaml", "the config file")

func main() {
	var err error

	flag.Parse()

	// Load the configuration file
	var c config.Config
	conf.MustLoad(*configFile, &c, conf.UseEnv(), conf.UseFS(configFS))

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

	// TODO: add a job
	jobFunc := func() {
		// Run the job logic in a go routine to prevent blocking
		// TODO: add the logic for the job
	}

	// Run the job immediately on startup
	go jobFunc()

	// Register the job to run every 10 minutes with cron
	err = svcCtx.JobManager.AddJob("0 */10 * * * *", jobFunc)
	if err != nil {
		panic(err)
	}

	// Start the job manager
	go svcCtx.JobManager.Start()
	defer svcCtx.JobManager.Stop()

	// Start the server
	fmt.Printf("Starting server at %s:%d ...\n", c.Host, c.Port)
	server.Start()
}
