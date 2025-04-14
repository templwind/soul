package listpostsbytag

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListPostsByTagLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListPostsByTagLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListPostsByTagLogic {
	return &ListPostsByTagLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListPostsByTagLogic) GetListPostsByTag(c echo.Context) (resp *[]types.BlogPost, err error) {
	// todo: add your logic here and delete this line

	return
}
