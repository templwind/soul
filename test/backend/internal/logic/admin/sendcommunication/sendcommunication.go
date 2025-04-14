package sendcommunication

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type SendCommunicationLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewSendCommunicationLogic(ctx context.Context, svcCtx *svc.ServiceContext) *SendCommunicationLogic {
	return &SendCommunicationLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *SendCommunicationLogic) PostSendCommunication(c echo.Context, req *types.AdminUserRequest) (resp *types.NotificationResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
