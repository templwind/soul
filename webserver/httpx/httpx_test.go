package httpx

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
)

// TestStruct is a sample struct for testing.
type TestStruct struct {
	PublicID        string `path:"publicID"`
	Email           string `query:"email" validate:"required,email"`
	Password        string `form:"password" json:"password" validate:"required,min=6,max=32"`
	ConfirmPassword string `form:"confirm_password" json:"confirm_password" validate:"required,min=6,max=32"`
	HeaderValue     string `header:"X-Custom-Header" validate:"required"`
}

// TestValidator is a mock validator to test the custom validation.
type TestValidator struct{}

func (v *TestValidator) Validate(c echo.Context, data any) error {
	if ts, ok := data.(*TestStruct); ok {
		if ts.Password != ts.ConfirmPassword {
			return errors.New("passwords do not match")
		}
	}
	return nil
}

func init() {
	// Set the custom validator.
	SetValidator(&TestValidator{})
}

// TestParseSuccess tests the successful parsing of all parameters.
func TestParseSuccess(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", strings.NewReader("password=strongpass&confirm_password=strongpass"))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.NoError(t, err)
	assert.Equal(t, "123", ts.PublicID)
	assert.Equal(t, "test@example.com", ts.Email)
	assert.Equal(t, "strongpass", ts.Password)
	assert.Equal(t, "strongpass", ts.ConfirmPassword)
	assert.Equal(t, "HeaderValue", ts.HeaderValue)
}

// TestParseJsonSuccess tests the successful parsing of all parameters using JSON body.
func TestParseJsonSuccess(t *testing.T) {
	e := echo.New()
	jsonBody := `{"password": "strongpass", "confirm_password": "strongpass"}`
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", bytes.NewReader([]byte(jsonBody)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.NoError(t, err)
	assert.Equal(t, "123", ts.PublicID)
	assert.Equal(t, "test@example.com", ts.Email)
	assert.Equal(t, "strongpass", ts.Password)
	assert.Equal(t, "strongpass", ts.ConfirmPassword)
	assert.Equal(t, "HeaderValue", ts.HeaderValue)
}

// TestParseMixingJsonAndFormData tests that mixing JSON and form data in the same struct is not allowed.
func TestParseMixingJsonAndFormData(t *testing.T) {
	e := echo.New()

	// Prepare a request with form data
	formData := "password=strongpass&confirm_password=strongpass"
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", strings.NewReader(formData))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	// Parse the form data
	err := req.ParseForm()
	assert.NoError(t, err)

	// Now add JSON content type, which should cause a conflict
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err = Parse(c, ts, "/users/:publicID")

	assert.Error(t, err)
	if err != nil {
		assert.Contains(t, err.Error(), "cannot mix form and json data")
	}
}

// TestParseMissingHeader tests missing header validation.
func TestParseMissingHeader(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", strings.NewReader("password=strongpass&confirm_password=strongpass"))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.Error(t, err)
	assert.Equal(t, "field HeaderValue: is required", err.Error())
}

// TestParseJsonBody tests parsing JSON body.
func TestParseJsonBody(t *testing.T) {
	e := echo.New()
	jsonBody := `{"password": "strongpass", "confirm_password": "strongpass"}`
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", bytes.NewReader([]byte(jsonBody)))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.NoError(t, err)
	assert.Equal(t, "123", ts.PublicID)
	assert.Equal(t, "test@example.com", ts.Email)
	assert.Equal(t, "strongpass", ts.Password)
	assert.Equal(t, "strongpass", ts.ConfirmPassword)
	assert.Equal(t, "HeaderValue", ts.HeaderValue)
}

// TestParseInvalidEmail tests validation of invalid email.
func TestParseInvalidEmail(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=invalid-email", strings.NewReader("password=strongpass&confirm_password=strongpass"))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.Error(t, err)
	if err != nil {
		assert.Contains(t, err.Error(), "field Email: invalid-email does not validate as email")
	}
}

// TestParsePathMismatch tests path mismatch error.
func TestParsePathMismatch(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/mismatch/123", strings.NewReader("password=strongpass&confirm_password=strongpass"))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/mismatch/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.Error(t, err)
	if err != nil {
		assert.Contains(t, err.Error(), "path does not match pattern")
	}
}

// TestParsePasswordMismatch tests custom validation logic.
func TestParsePasswordMismatch(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/users/123?email=test@example.com", strings.NewReader("password=password1&confirm_password=password2"))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/users/:publicID")
	c.SetParamNames("publicID")
	c.SetParamValues("123")

	ts := new(TestStruct)
	err := Parse(c, ts, "/users/:publicID")

	assert.Error(t, err)
	if err != nil {
		assert.Equal(t, "passwords do not match", err.Error())
	}
}

// TestExtractPathVarsWithEmbeddedParam tests extraction of path variables with embedded parameters.
func TestExtractPathVarsWithEmbeddedParam(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/fashion-beauty-influencers-winter", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/fashion-beauty-influencers-:suffix")

	vars, err := extractPathVars(c, "/fashion-beauty-influencers-:suffix")
	assert.NoError(t, err)
	assert.Equal(t, "winter", vars["suffix"])

	req = httptest.NewRequest(http.MethodGet, "/fashion-beauty-influencers-2022", nil)
	rec = httptest.NewRecorder()
	c = e.NewContext(req, rec)
	c.SetPath("/fashion-beauty-influencers-:suffix")

	vars, err = extractPathVars(c, "/fashion-beauty-influencers-:suffix")
	assert.NoError(t, err)
	assert.Equal(t, "2022", vars["suffix"])
}
