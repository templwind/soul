package regenerateapikey

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type RegenerateApiKeyLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewRegenerateApiKeyLogic(ctx context.Context, svcCtx *svc.ServiceContext) *RegenerateApiKeyLogic {
	return &RegenerateApiKeyLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *RegenerateApiKeyLogic) PostRegenerateApiKey(c echo.Context) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
