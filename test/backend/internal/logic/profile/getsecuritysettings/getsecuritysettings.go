package getsecuritysettings

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetSecuritySettingsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetSecuritySettingsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetSecuritySettingsLogic {
	return &GetSecuritySettingsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetSecuritySettingsLogic) GetSecuritySettings(c echo.Context) (resp *types.SecuritySettings, err error) {
	// todo: add your logic here and delete this line

	return
}
