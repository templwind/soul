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

func SetAccountToken(c echo.Context, cfg *config.Config, userAccount *models.UserAccount) error {
	token, err := newAccountToken(cfg, userAccount)
	if err != nil {
		return err
	}

	session.SetCookie(cfg, c, token, cfg.Auth.AccountCookieName)
	return nil
}

// newAccountToken generates and returns a new auth record authentication token.
func newAccountToken(cfg *config.Config, userAccount *models.UserAccount) (string, error) {
	duration := time.Duration(cfg.Auth.AccessExpire) * time.Second
	expirationTime := time.Now().Add(duration)

	return security.NewJWT(
		jwt.MapClaims{
			"id":     userAccount.AccountID,
			"userID": userAccount.UserID,
		},
		(cfg.Auth.AccessSecret),
		expirationTime.Unix(),
	)
}
