// Code generated by goctl. DO NOT EDIT.
package handler

import (
	{{if .hasTimeout}}
	"time"
	
	{{end}}

	{{.importPackages}}
)

type jwtCustomClaims struct {
	Name  string `json:"name"`
	Admin bool   `json:"admin"`
	jwt.RegisteredClaims
}

func RegisterHandlers(server *echo.Echo, svcCtx *svc.ServiceContext) {
	{{.routesAdditions}}

	// The following code is used to handle the 404 error.
	server.Any("/*", notfound.NotFoundHandler(svcCtx))
}