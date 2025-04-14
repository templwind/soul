package getemailpreferences

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetEmailPreferencesLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetEmailPreferencesLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetEmailPreferencesLogic {
	return &GetEmailPreferencesLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetEmailPreferencesLogic) GetEmailPreferences(c echo.Context) (resp *types.EmailPreferences, err error) {
	// todo: add your logic here and delete this line

	return
}
