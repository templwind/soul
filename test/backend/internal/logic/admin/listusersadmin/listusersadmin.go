package listusersadmin

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListUsersAdminLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListUsersAdminLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListUsersAdminLogic {
	return &ListUsersAdminLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListUsersAdminLogic) GetListUsersAdmin(c echo.Context) (resp *[]types.User, err error) {
	// todo: add your logic here and delete this line

	return
}
