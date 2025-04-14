package cancelinvitation

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type CancelInvitationLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCancelInvitationLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CancelInvitationLogic {
	return &CancelInvitationLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CancelInvitationLogic) DeleteCancelInvitation(c echo.Context, req *types.TeamInvitationRequest) (resp *types.InvitationResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
