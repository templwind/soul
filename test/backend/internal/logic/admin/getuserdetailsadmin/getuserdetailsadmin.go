package getuserdetailsadmin

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetUserDetailsAdminLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetUserDetailsAdminLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetUserDetailsAdminLogic {
	return &GetUserDetailsAdminLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetUserDetailsAdminLogic) GetUserDetailsAdmin(c echo.Context, req *types.AdminUserRequest) (resp *types.AdminUserResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
