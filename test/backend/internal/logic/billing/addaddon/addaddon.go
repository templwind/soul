package addaddon

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type AddAddonLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewAddAddonLogic(ctx context.Context, svcCtx *svc.ServiceContext) *AddAddonLogic {
	return &AddAddonLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *AddAddonLogic) PostAddAddon(c echo.Context, req *types.AddonRequest) (resp *types.AddonResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
