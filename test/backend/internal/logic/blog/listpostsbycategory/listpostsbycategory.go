package listpostsbycategory

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type ListPostsByCategoryLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewListPostsByCategoryLogic(ctx context.Context, svcCtx *svc.ServiceContext) *ListPostsByCategoryLogic {
	return &ListPostsByCategoryLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *ListPostsByCategoryLogic) GetListPostsByCategory(c echo.Context) (resp *[]types.BlogPost, err error) {
	// todo: add your logic here and delete this line

	return
}
