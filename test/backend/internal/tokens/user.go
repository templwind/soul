package tokens

import (
	"time"

	"backend/internal/config"
	"backend/internal/models"
	"backend/internal/security"
	"backend/internal/session"

	"github.com/golang-jwt/jwt/v4"
	"github.com/labstack/echo/v4"
)

func SetUserToken(c echo.Context, cfg *config.Config, user *models.User) error {
	token, err := newUserToken(cfg, user)
	if err != nil {
		return err
	}

	session.SetCookie(cfg, c, token, cfg.Auth.UserCookieName)
	return nil
}

// newUserToken generates and returns a new user authentication token.
func newUserToken(cfg *config.Config, user *models.User) (string, error) {
	duration := time.Duration(cfg.Auth.AccessExpire) * time.Second
	expirationTime := time.Now().Add(duration)

	return security.NewJWT(
		jwt.MapClaims{
			"id":         user.ID,
			"title":      user.Title,
			"first_name": user.FirstName,
			"last_name":  user.LastName,
			"email":      user.Email,
		},
		cfg.Auth.AccessSecret,
		expirationTime.Unix(),
	)
}
