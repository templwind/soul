package login

import (
	"{{ .ModuleName }}/internal/svc"
)

type Controller struct {
	svcCtx *svc.ServiceContext
	form   *LoginForm
}

func NewController(svcCtx *svc.ServiceContext) *Controller {
	return &Controller{
		svcCtx: svcCtx,
		form:   new(LoginForm),
	}
}
