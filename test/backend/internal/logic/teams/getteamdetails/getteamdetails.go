package getteamdetails

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetTeamDetailsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetTeamDetailsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetTeamDetailsLogic {
	return &GetTeamDetailsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetTeamDetailsLogic) GetTeamDetails(c echo.Context, req *types.TeamRequest) (resp *types.TeamResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
