package updateemailpreferences

import (
	"context"

	"backend/internal/svc"
	"backend/internal/types"

	"github.com/labstack/echo/v4"
	"github.com/zeromicro/go-zero/core/logx"
)

type UpdateEmailPreferencesLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewUpdateEmailPreferencesLogic(ctx context.Context, svcCtx *svc.ServiceContext) *UpdateEmailPreferencesLogic {
	return &UpdateEmailPreferencesLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *UpdateEmailPreferencesLogic) PutUpdateEmailPreferences(c echo.Context, req *types.EmailPreferences) (resp *types.Response, err error) {
	// todo: add your logic here and delete this line

	return
}
