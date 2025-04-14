package getapiusagestats

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetAPIUsageStatsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetAPIUsageStatsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetAPIUsageStatsLogic {
	return &GetAPIUsageStatsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetAPIUsageStatsLogic) GetAPIUsageStats(c echo.Context) (resp *types.APIUsageStats, err error) {
	// todo: add your logic here and delete this line

	return
}
