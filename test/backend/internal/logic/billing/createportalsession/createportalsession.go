package createportalsession

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type CreatePortalSessionLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewCreatePortalSessionLogic(ctx context.Context, svcCtx *svc.ServiceContext) *CreatePortalSessionLogic {
	return &CreatePortalSessionLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *CreatePortalSessionLogic) PostCreatePortalSession(c echo.Context) (resp *types.PortalSessionResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
