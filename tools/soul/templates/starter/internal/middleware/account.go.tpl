package middleware

import (
	"net/http"
	"strings"

	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/security"
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/internal/tokens"

	"github.com/labstack/echo/v4"
)

const AccountCookieName = "account"

func SetAccountToken(e echo.Context, svcCtx *svc.ServiceContext, userAccount *models.UserAccount) error {
	token, err := tokens.NewAccountToken(svcCtx, userAccount)
	if err != nil {
		return err
	}

	e.SetCookie(&http.Cookie{
		Name:     AccountCookieName,
		Value:    token,
		Path:     "/",
		Secure:   e.Request().URL.Scheme == "https",
		HttpOnly: true,
	})

	return nil
}

func LoadAccountContextFromCookie(svcCtx *svc.ServiceContext) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(e echo.Context) error {
			tokenCookie, err := e.Request().Cookie(AccountCookieName)
			if err != nil {
				// fmt.Println("tokenCookie:", err)
				return next(e)
			}

			token := tokenCookie.Value

			unverifiedClaims, err := security.ParseUnverifiedJWT(token)
			if err != nil {
				// fmt.Println("ParseUnverifiedJWT:", err)
				return next(e)
			}

			// check required claims
			id, _ := unverifiedClaims["id"].(string)

			// find account by id
			account, err := models.AccountByID(e.Request().Context(), svcCtx.SqlxDB, id)
			if err != nil {
				// fmt.Println(err)
				return next(e)
			}

			// verify token signature
			if _, err := security.ParseJWT(token, tokens.AccountTokenPrefix+svcCtx.Config.Auth.TokenSecret); err != nil {
				// fmt.Println(err)
				return next(e)
			}
			e.Set(ContextAccountKey, account)

			// fmt.Println("auth middleware: token verified")
			return next(e)
		}
	}
}

func AccountGuard(next echo.HandlerFunc) echo.HandlerFunc {
	return func(e echo.Context) error {
		// make sure we're not on choose-account page
		if strings.Contains(e.Path(), "/app/choose-account") {
			// fmt.Println("choose-account page")
			return next(e)
		}

		if AccountFromContext(e) != nil {
			// fmt.Println("has valid account")
			return next(e)
		}

		return e.Redirect(302, "/app/choose-account")
	}
}
