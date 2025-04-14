package session

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"backend/internal/config"

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
func (s *Session) set(c echo.Context, key string, value any) error {
	sess, err := s.GetSession(c)
	if err != nil {
		fmt.Println("Error getting session for set:", err)
		return err
	}
	sess.Values[key] = value
	return sess.Save(c.Request(), c.Response())
}

func Set[T any](s *Session, c echo.Context, key string, value any) error {
	// Convert the value to the expected type T using a helper function
	convertedValue, err := convertToType[T](value)
	if err != nil {
		return fmt.Errorf("failed to convert value to type %T: %w", convertedValue, err)
	}

	return s.set(c, key, convertedValue)
}

// Helper function to handle conversion to the specified type
func convertToType[T any](value any) (T, error) {
	var zeroValue T // default value of T
	switch any(zeroValue).(type) {
	case int:
		converted := safeTypeConversion(value)
		if intVal, ok := converted.(int); ok {
			return any(intVal).(T), nil
		}
	case int8:
		converted := safeTypeConversion(value)
		if intVal, ok := converted.(int8); ok {
			return any(intVal).(T), nil
		}
	case int16:
		converted := safeTypeConversion(value)
		if intVal, ok := converted.(int16); ok {
			return any(intVal).(T), nil
		}
	case int32:
		converted := safeTypeConversion(value)
		if intVal, ok := converted.(int32); ok {
			return any(intVal).(T), nil
		}
	case int64:
		converted := safeTypeConversion(value)
		if intVal, ok := converted.(int64); ok {
			return any(intVal).(T), nil
		}
	case uint:
		converted := safeTypeConversion(value)
		if uintVal, ok := converted.(uint); ok {
			return any(uintVal).(T), nil
		}
	case uint8:
		converted := safeTypeConversion(value)
		if uintVal, ok := converted.(uint8); ok {
			return any(uintVal).(T), nil
		}
	case uint16:
		converted := safeTypeConversion(value)
		if uintVal, ok := converted.(uint16); ok {
			return any(uintVal).(T), nil
		}
	case uint32:
		converted := safeTypeConversion(value)
		if uintVal, ok := converted.(uint32); ok {
			return any(uintVal).(T), nil
		}
	case uint64:
		converted := safeTypeConversion(value)
		if uintVal, ok := converted.(uint64); ok {
			return any(uintVal).(T), nil
		}
	case float32:
		converted := safeTypeConversion(value)
		if floatVal, ok := converted.(float32); ok {
			return any(floatVal).(T), nil
		}
	case float64:
		converted := safeTypeConversion(value)
		if floatVal, ok := converted.(float64); ok {
			return any(floatVal).(T), nil
		}
	case string:
		converted := safeTypeConversion(value)
		if strVal, ok := converted.(string); ok {
			return any(strVal).(T), nil
		}
	case bool:
		converted := safeTypeConversion(value)
		if boolVal, ok := converted.(bool); ok {
			return any(boolVal).(T), nil
		}
	case complex64:
		if compVal, ok := value.(complex64); ok {
			return any(compVal).(T), nil
		}
	case complex128:
		if compVal, ok := value.(complex128); ok {
			return any(compVal).(T), nil
		}
	case []byte:
		if byteVal, ok := value.([]byte); ok {
			return any(byteVal).(T), nil
		}
	case time.Time:
		if timeVal, ok := value.(time.Time); ok {
			return any(timeVal).(T), nil
		}
	case map[string]any:
		if mapVal, ok := value.(map[string]any); ok {
			return any(mapVal).(T), nil
		}
	case []any:
		if sliceVal, ok := value.([]any); ok {
			return any(sliceVal).(T), nil
		}
	default:
		if converted, ok := value.(T); ok {
			return converted, nil
		}
	}

	return zeroValue, fmt.Errorf("cannot convert value of type %T to %T", value, zeroValue)
}

// Get retrieves a value from the session
// Get retrieves a value from the session with safe type conversion
func (s *Session) get(c echo.Context, key string) (any, error) {
	sess, err := s.GetSession(c)
	if err != nil {
		fmt.Println("Error getting session for get:", err)
		return nil, err
	}

	value, ok := sess.Values[key]
	if !ok {
		fmt.Println("Key not found for get:", key)
		return nil, nil // or return a default value if key not found
	}

	// Handle potential type issues here
	return value, nil
}

func Get[T any](s *Session, c echo.Context, key string) (T, error) {
	var zeroValue T // default value of T
	sess, err := s.get(c, key)
	if err != nil {
		fmt.Println("Error getting session for get:", err)
		return zeroValue, err
	}

	value, ok := sess.(T)
	if !ok {
		fmt.Println("Type assertion failed for key:", key)
		return zeroValue, fmt.Errorf("type assertion failed for key: %s", key)
	}

	return value, nil
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
	case bool:
		return v
	case float32:
		return int(v)
	case uint64:
		return int(v)
	case uint32:
		return int(v)
	case uint16:
		return int(v)
	case uint8:
		return int(v)
	case uint:
		return int(v)
	case int8:
		return int(v)
	case int16:
		return int(v)
	case int32:
		return int(v)
	case int64:
		return int(v)
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
