package account

import (
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

func (c *Controller) HandleGet(e echo.Context) error {
	return utils.Render(e, 200, New(
		WithConfig(c.svcCtx.Config),
		WithEcho(e),
	))
}
