package googlelogin

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GoogleLoginLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGoogleLoginLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GoogleLoginLogic {
	return &GoogleLoginLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GoogleLoginLogic) GetGoogleLogin(c echo.Context) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
