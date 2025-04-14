package getdashboardmetrics

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetDashboardMetricsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetDashboardMetricsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetDashboardMetricsLogic {
	return &GetDashboardMetricsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetDashboardMetricsLogic) GetDashboardMetrics(c echo.Context) (resp *types.DashboardMetrics, err error) {
	// todo: add your logic here and delete this line

	return
}
