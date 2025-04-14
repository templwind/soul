package listteams

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListTeamsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListTeamsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListTeamsLogic {
	return &ListTeamsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListTeamsLogic) GetListTeams(c echo.Context) (resp *[]types.Team, err error) {
	// todo: add your logic here and delete this line

	return
}
