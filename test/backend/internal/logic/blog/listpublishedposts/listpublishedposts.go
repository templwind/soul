package listpublishedposts

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListPublishedPostsLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListPublishedPostsLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListPublishedPostsLogic {
	return &ListPublishedPostsLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListPublishedPostsLogic) GetListPublishedPosts(c echo.Context) (resp *[]types.BlogPost, err error) {
	// todo: add your logic here and delete this line

	return
}
