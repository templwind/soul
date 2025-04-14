// Code generated by soul. DO NOT EDIT.
package auth

import (
	"net/http"

	logicHandler "backend/internal/logic/auth/requestlogincode"
	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/templwind/soul/webserver/httpx"
)

func PostRequestLoginCodeHandler(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
	return func(c echo.Context) error {
		var req types.LoginCodeRequest
		if err := httpx.Parse(c, &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		l := logicHandler.NewRequestLoginCodeLogic(c.Request().Context(), svcCtx)
		resp, err := l.PostRequestLoginCode(c, &req)
		if err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		return c.JSON(http.StatusOK, resp)
	}
}
