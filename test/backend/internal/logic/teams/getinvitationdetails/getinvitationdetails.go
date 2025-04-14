package getinvitationdetails

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetInvitationDetailsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetInvitationDetailsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetInvitationDetailsLogic {
	return &GetInvitationDetailsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetInvitationDetailsLogic) GetInvitationDetails(c echo.Context, req *types.InvitationTokenRequest) (resp *types.InvitationResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
