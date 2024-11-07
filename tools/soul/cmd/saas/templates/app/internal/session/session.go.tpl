package session

import (
	"fmt"
	"net/http"
	"strconv"

	"{{ .serviceName }}/internal/config"

	"github.com/gorilla/sessions"
	"github.com/labstack/echo-contrib/session"
	"github.com/labstack/echo/v4"
)

const (
	SessionName string = "sess"
)

type Session struct {
	cfg   *config.Config
	store sessions.Store
}

func NewSession(cfg *config.Config) *Session {
	store := sessions.NewCookieStore([]byte(cfg.Auth.SecretKey))
	store.Options = &sessions.Options{
		Path:     "/",
		MaxAge:   int(cfg.Auth.AccessExpire),
		HttpOnly: true,
		Secure:   cfg.Environment == "production",
	}
	return &Session{
		cfg:   cfg,
		store: store,
	}
}

// InitializeSessionStore sets up the session store
func (s *Session) InitializeSessionStore(e *echo.Echo) {
	if s.store != nil {
		e.Use(session.Middleware(s.store))
	}
}

// GetSession retrieves the session from the context
func (s *Session) GetSession(c echo.Context) (*sessions.Session, error) {
	sess, err := session.Get(SessionName, c)
	if err != nil {
		return nil, err
	}
	if sess == nil {
		return nil, fmt.Errorf("session is nil")
	}
	return sess, nil
}

// Set sets a value in the session
func (s *Session) Set(c echo.Context, key string, value any) error {
	sess, err := s.GetSession(c)
	if err != nil {
		return err
	}
	sess.Values[key] = value
	return sess.Save(c.Request(), c.Response())
}

// Get retrieves a value from the session
// Get retrieves a value from the session with safe type conversion
func (s *Session) Get(c echo.Context, key string) (any, error) {
	sess, err := s.GetSession(c)
	if err != nil {
		return nil, err
	}

	value, ok := sess.Values[key]
	if !ok {
		return nil, nil // or return a default value if key not found
	}

	// Handle potential type issues here
	return safeTypeConversion(value), nil
}

// safeTypeConversion handles converting session values to expected types
func safeTypeConversion(value any) any {
	switch v := value.(type) {
	case int:
		return v
	case float64:
		return int(v)
	case string:
		if intVal, err := strconv.Atoi(v); err == nil {
			return intVal
		}
		return v
	case []uint8: // Typically how strings are stored in some session stores
		return string(v)
	default:
		// Return value as is or handle other expected types
		return v
	}
}

func (s *Session) SetCookie(c echo.Context, token string, cookieName string) {
	c.SetCookie(&http.Cookie{
		Name:     cookieName,
		Value:    token,
		Path:     "/",
		Secure:   c.Request().URL.Scheme == "https",
		HttpOnly: true,
		MaxAge:   int(s.cfg.Auth.AccessExpire),
	})
}

func (s *Session) GetCookie(c echo.Context, cookieName string) string {
	cookie, err := c.Cookie(cookieName)
	if err != nil {
		return ""
	}
	return cookie.Value
}

func (s *Session) ClearCookies(c echo.Context, cookieNames ...string) {
	for _, cookieName := range cookieNames {
		c.SetCookie(&http.Cookie{
			Name:     cookieName,
			Value:    "",
			Path:     "/",
			Secure:   true,
			HttpOnly: true,
			MaxAge:   -1,
		})
	}
}

// ClearSession removes all values from the session
func (s *Session) ClearSession(c echo.Context) error {
	sess, err := s.GetSession(c)
	if err != nil {
		return err
	}
	sess.Values = make(map[any]any)
	return sess.Save(c.Request(), c.Response())
}
