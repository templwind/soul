package middleware

import (
	"net/http"

	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/security"
	"{{ .ModuleName }}/internal/svc"
	"{{ .ModuleName }}/internal/tokens"

	"github.com/labstack/echo/v4"
)

const AuthCookieName = "auth"

func SetAuthToken(e echo.Context, svcCtx *svc.ServiceContext, user *models.User) error {
	token, err := tokens.NewUserAuthToken(svcCtx, user)
	if err != nil {
		return err
	}

	e.SetCookie(&http.Cookie{
		Name:     AuthCookieName,
		Value:    token,
		Path:     "/",
		Secure:   e.Request().URL.Scheme == "https",
		HttpOnly: true,
	})

	return nil
}

func LoadAuthContextFromCookie(svcCtx *svc.ServiceContext) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(e echo.Context) error {
			tokenCookie, err := e.Request().Cookie(AuthCookieName)
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

			// find user by id
			user, err := models.UserByID(e.Request().Context(), svcCtx.SqlxDB, id)
			if err != nil {
				// fmt.Println(err)
				return next(e)
			}

			// verify token signature
			if _, err := security.ParseJWT(token, user.TokenKey+svcCtx.Config.Auth.TokenSecret); err != nil {
				// fmt.Println(err)
				return next(e)
			}
			e.Set(ContextUserKey, user)

			// fmt.Println("auth middleware: token verified")
			return next(e)
		}
	}
}

func AuthGuard(next echo.HandlerFunc) echo.HandlerFunc {
	return func(e echo.Context) error {

		if UserFromContext(e) != nil {
			// fmt.Println("user is authenticated")
			return next(e)
		}

		return e.Redirect(302, "/login")
	}
}
