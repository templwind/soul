package createcheckoutsession

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type CreateCheckoutSessionLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreateCheckoutSessionLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreateCheckoutSessionLogic {
	return &CreateCheckoutSessionLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreateCheckoutSessionLogic) PostCreateCheckoutSession(c echo.Context, req *types.CheckoutSessionRequest) (resp *types.CheckoutSessionResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
