package removeaddon

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type RemoveAddonLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRemoveAddonLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RemoveAddonLogic {
	return &RemoveAddonLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RemoveAddonLogic) DeleteRemoveAddon(c echo.Context, req *types.AddonRequest) (resp *types.AddonResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
