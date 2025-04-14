package getpostbyslug

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetPostBySlugLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetPostBySlugLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetPostBySlugLogic {
	return &GetPostBySlugLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetPostBySlugLogic) GetPostBySlug(c echo.Context) (resp *types.BlogPost, err error) {
	// todo: add your logic here and delete this line

	return
}
