package googlecallback

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GoogleCallbackLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGoogleCallbackLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GoogleCallbackLogic {
	return &GoogleCallbackLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GoogleCallbackLogic) GetGoogleCallback(c echo.Context) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
