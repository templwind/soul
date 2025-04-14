package verifylogincode

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type VerifyLoginCodeLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewVerifyLoginCodeLogic(ctx context.Context, svcCtx *svc.ServiceContext) *VerifyLoginCodeLogic {
	return &VerifyLoginCodeLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *VerifyLoginCodeLogic) PostVerifyLoginCode(c echo.Context, req *types.VerifyCodeRequest) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
