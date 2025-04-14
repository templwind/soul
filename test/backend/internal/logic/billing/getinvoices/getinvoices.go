package getinvoices

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type GetInvoicesLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewGetInvoicesLogic(ctx context.Context, svcCtx *svc.ServiceContext) *GetInvoicesLogic {
	return &GetInvoicesLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *GetInvoicesLogic) GetInvoices(c echo.Context) (resp *types.InvoiceResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
