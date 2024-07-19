package modules

import (
	"{{ .ModuleName }}/internal/svc"

	"github.com/labstack/echo/v4"
)

// Module interface that all modules must implement
type Module interface {
	Register(svcCtx *svc.ServiceContext, e *echo.Echo) error
}

func RegisterAll(svcCtx *svc.ServiceContext, e *echo.Echo) error {
	for _, m := range registry {
		err := m.Register(svcCtx, e)
		if err != nil {
			return err
		}
	}
	return nil
}
