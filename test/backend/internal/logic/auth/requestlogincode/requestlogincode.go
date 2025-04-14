package requestlogincode

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type RequestLoginCodeLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRequestLoginCodeLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RequestLoginCodeLogic {
	return &RequestLoginCodeLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RequestLoginCodeLogic) PostRequestLoginCode(c echo.Context, req *types.LoginCodeRequest) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
