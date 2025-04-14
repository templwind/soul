package listusercommunications

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListUserCommunicationsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListUserCommunicationsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListUserCommunicationsLogic {
	return &ListUserCommunicationsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListUserCommunicationsLogic) GetListUserCommunications(c echo.Context, req *types.AdminUserRequest) (resp *types.AdminUserCommunicationsResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
