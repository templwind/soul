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

func TestParsePathWithEmbeddedParams(t *testing.T) {
	e := echo.New()

	type TestStruct struct {
		Suffix string `path:"suffix"`
		Year   string `path:"year"`
	}

	testCases := []struct {
		name           string
		requestPath    string
		patternPath    string
		expectedSuffix string
		expectedYear   string
		expectError    bool
	}{
		{
			name:           "Direct match",
			requestPath:    "/fashion-beauty-influencers-winter",
			patternPath:    "/fashion-beauty-influencers-:suffix",
			expectedSuffix: "winter",
			expectedYear:   "",
			expectError:    false,
		},
		{
			name:           "Another direct match",
			requestPath:    "/fashion-beauty-influencers-2022",
			patternPath:    "/fashion-beauty-influencers-:suffix",
			expectedSuffix: "2022",
			expectedYear:   "",
			expectError:    false,
		},
		{
			name:           "Additional segment before pattern",
			requestPath:    "/discover/fashion-beauty-influencers-abcd",
			patternPath:    "/discover/fashion-beauty-influencers-:suffix",
			expectedSuffix: "abcd",
			expectedYear:   "",
			expectError:    false,
		},
		{
			name:           "Mismatch in pattern",
			requestPath:    "/mismatch/fashion-beauty-influencers-xyz",
			patternPath:    "/discover/fashion-beauty-influencers-:suffix",
			expectedSuffix: "",
			expectedYear:   "",
			expectError:    true,
		},
		{
			name:           "Multiple embedded parameters",
			requestPath:    "/fashion-beauty-influencers-winter-2023",
			patternPath:    "/fashion-beauty-influencers-:suffix-:year",
			expectedSuffix: "winter",
			expectedYear:   "2023",
			expectError:    false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tc.requestPath, nil)
			rec := httptest.NewRecorder()
			c := e.NewContext(req, rec)
			c.SetPath(tc.patternPath)

			ts := new(TestStruct)
			err := ParsePath(c, ts, tc.patternPath)

			if tc.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
				assert.Equal(t, tc.expectedSuffix, ts.Suffix)
				assert.Equal(t, tc.expectedYear, ts.Year)
			}
		})
	}
}

// FormDataStruct is a struct for testing form data parsing.
type FormDataStruct struct {
	Password        string `form:"password" validate:"required,min=6,max=32"`
	ConfirmPassword string `form:"confirm_password" validate:"required,min=6,max=32"`
}

// TestPostFormWithoutAdditionalPath tests the POST form handling without additional parts to the path.
func TestPostFormWithoutAdditionalPath(t *testing.T) {
	e := echo.New()

	// Prepare a request with form data
	formData := "password=strongpass&confirm_password=strongpass"
	req := httptest.NewRequest(http.MethodPost, "/onboarding/checkout", strings.NewReader(formData))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	req.Header.Set("X-Custom-Header", "HeaderValue")

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/onboarding/checkout")

	// Use the new FormDataStruct
	fds := new(FormDataStruct)
	err := Parse(c, fds, "/onboarding/checkout")

	assert.NoError(t, err)
	assert.Equal(t, "strongpass", fds.Password)
	assert.Equal(t, "strongpass", fds.ConfirmPassword)
}
