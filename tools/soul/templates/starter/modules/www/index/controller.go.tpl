package index

import (
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/internal/utils"

	"github.com/labstack/echo/v4"
)

type Controller struct {
	svcCtx *svc.ServiceContext
}

func NewController(svcCtx *svc.ServiceContext) *Controller {
	return &Controller{
		svcCtx: svcCtx,
	}
}

func (c *Controller) HandleGet(e echo.Context) error {
	return utils.Render(e, 200, New(
		WithConfig(c.svcCtx.Config),
		WithEcho(e),
	))
}
