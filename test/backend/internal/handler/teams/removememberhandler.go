// Code generated by soul. DO NOT EDIT.
package teams

import (
	"net/http"

	logicHandler "backend/internal/logic/teams/removemember"
	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/templwind/soul/webserver/httpx"
)

func DeleteRemoveMemberHandler(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
	return func(c echo.Context) error {
		var req types.TeamMemberRequest
		if err := httpx.Parse(c, &req, path); err != nil {
			c.Logger().Error(err)
			return c.JSON(http.StatusInternalServerError, map[string]interface{}{
				"error": "Internal Server Error",
				"msg":   err.Error(),
			})
		}
		l := logicHandler.NewRemoveMemberLogic(c.Request().Context(), svcCtx)
		resp, err := l.DeleteRemoveMember(c, &req)
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
