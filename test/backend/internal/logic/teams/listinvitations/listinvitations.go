package listinvitations

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListInvitationsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListInvitationsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListInvitationsLogic {
	return &ListInvitationsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListInvitationsLogic) GetListInvitations(c echo.Context, req *types.TeamRequest) (resp *types.TeamInvitationsResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
