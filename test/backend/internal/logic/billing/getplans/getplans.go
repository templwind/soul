package getplans

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetPlansLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetPlansLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetPlansLogic {
	return &GetPlansLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetPlansLogic) GetPlans(c echo.Context) (resp *[]types.Plan, err error) {
	// todo: add your logic here and delete this line

	return
}
