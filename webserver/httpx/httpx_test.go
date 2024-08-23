package httpx

import (
	"bytes"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

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
		// test with no embedded parameters
		{
			name:           "No embedded parameters",
			requestPath:    "/fashion-beauty-influencers",
			patternPath:    "/fashion-beauty-influencers",
			expectedSuffix: "",
			expectedYear:   "",
			expectError:    false,
		},
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

// PathParseStruct is a struct for testing path parameter parsing
type PathParseStruct struct {
	BoolField    bool      `path:"bool_field"`
	IntField     int       `path:"int_field"`
	Int8Field    int8      `path:"int8_field"`
	Int16Field   int16     `path:"int16_field"`
	Int32Field   int32     `path:"int32_field"`
	Int64Field   int64     `path:"int64_field"`
	UintField    uint      `path:"uint_field"`
	Uint8Field   uint8     `path:"uint8_field"`
	Uint16Field  uint16    `path:"uint16_field"`
	Uint32Field  uint32    `path:"uint32_field"`
	Uint64Field  uint64    `path:"uint64_field"`
	Float32Field float32   `path:"float32_field"`
	Float64Field float64   `path:"float64_field"`
	StringField  string    `path:"string_field"`
	TimeField    time.Time `path:"time_field"`
}

// FormParseStruct is a struct for testing form data parsing
type FormParseStruct struct {
	BoolField    bool              `form:"bool_field"`
	IntField     int               `form:"int_field"`
	Int8Field    int8              `form:"int8_field"`
	Int16Field   int16             `form:"int16_field"`
	Int32Field   int32             `form:"int32_field"`
	Int64Field   int64             `form:"int64_field"`
	UintField    uint              `form:"uint_field"`
	Uint8Field   uint8             `form:"uint8_field"`
	Uint16Field  uint16            `form:"uint16_field"`
	Uint32Field  uint32            `form:"uint32_field"`
	Uint64Field  uint64            `form:"uint64_field"`
	Float32Field float32           `form:"float32_field"`
	Float64Field float64           `form:"float64_field"`
	StringField  string            `form:"string_field"`
	TimeField    time.Time         `form:"time_field"`
	SliceField   []string          `form:"slice_field"`
	MapField     map[string]string `form:"map_field"`
}

// JSONParseStruct is a struct for testing JSON parsing
type JSONParseStruct struct {
	BoolField    bool              `json:"bool_field"`
	IntField     int               `json:"int_field"`
	Int8Field    int8              `json:"int8_field"`
	Int16Field   int16             `json:"int16_field"`
	Int32Field   int32             `json:"int32_field"`
	Int64Field   int64             `json:"int64_field"`
	UintField    uint              `json:"uint_field"`
	Uint8Field   uint8             `json:"uint8_field"`
	Uint16Field  uint16            `json:"uint16_field"`
	Uint32Field  uint32            `json:"uint32_field"`
	Uint64Field  uint64            `json:"uint64_field"`
	Float32Field float32           `json:"float32_field"`
	Float64Field float64           `json:"float64_field"`
	StringField  string            `json:"string_field"`
	TimeField    time.Time         `json:"time_field"`
	SliceField   []int             `json:"slice_field"`
	MapField     map[string]string `json:"map_field"`
	StructField  struct {
		NestedField string `json:"nested_field"`
	} `json:"struct_field"`
	InterfaceField interface{} `json:"interface_field"`
}

func TestComprehensivePathParse(t *testing.T) {
	e := echo.New()

	// Prepare path
	path := "/test/true/-42/-8/-16/-32/-64/42/8/16/32/64/3.14/3.14159/hello/2023-05-01T15:04:05Z"

	req := httptest.NewRequest(http.MethodGet, path, nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/test/:bool_field/:int_field/:int8_field/:int16_field/:int32_field/:int64_field/:uint_field/:uint8_field/:uint16_field/:uint32_field/:uint64_field/:float32_field/:float64_field/:string_field/:time_field")

	// Set path parameters
	c.SetParamNames("bool_field", "int_field", "int8_field", "int16_field", "int32_field", "int64_field", "uint_field", "uint8_field", "uint16_field", "uint32_field", "uint64_field", "float32_field", "float64_field", "string_field", "time_field")
	c.SetParamValues("true", "-42", "-8", "-16", "-32", "-64", "42", "8", "16", "32", "64", "3.14", "3.14159", "hello", "2023-05-01T15:04:05Z")

	pps := new(PathParseStruct)
	err := Parse(c, pps, c.Path())

	assert.NoError(t, err)

	assert.Equal(t, true, pps.BoolField)
	assert.Equal(t, -42, pps.IntField)
	assert.Equal(t, int8(-8), pps.Int8Field)
	assert.Equal(t, int16(-16), pps.Int16Field)
	assert.Equal(t, int32(-32), pps.Int32Field)
	assert.Equal(t, int64(-64), pps.Int64Field)
	assert.Equal(t, uint(42), pps.UintField)
	assert.Equal(t, uint8(8), pps.Uint8Field)
	assert.Equal(t, uint16(16), pps.Uint16Field)
	assert.Equal(t, uint32(32), pps.Uint32Field)
	assert.Equal(t, uint64(64), pps.Uint64Field)
	assert.InDelta(t, float32(3.14), pps.Float32Field, 0.00001)
	assert.InDelta(t, 3.14159, pps.Float64Field, 0.00000001)
	assert.Equal(t, "hello", pps.StringField)
	assert.Equal(t, time.Date(2023, time.May, 1, 15, 4, 5, 0, time.UTC), pps.TimeField)
}

func TestComprehensiveFormParse(t *testing.T) {
	e := echo.New()

	formData := url.Values{}
	formData.Set("bool_field", "true")
	formData.Set("int_field", "-42")
	formData.Set("int8_field", "-8")
	formData.Set("int16_field", "-16")
	formData.Set("int32_field", "-32")
	formData.Set("int64_field", "-64")
	formData.Set("uint_field", "42")
	formData.Set("uint8_field", "8")
	formData.Set("uint16_field", "16")
	formData.Set("uint32_field", "32")
	formData.Set("uint64_field", "64")
	formData.Set("float32_field", "3.14")
	formData.Set("float64_field", "3.14159")
	formData.Set("string_field", "hello")
	formData.Set("time_field", "2023-05-01T15:04:05Z")
	formData.Add("slice_field", "a")
	formData.Add("slice_field", "b")
	formData.Add("slice_field", "c")
	formData.Set("map_field", `{"key1":"value1","key2":"value2"}`)

	req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader(formData.Encode()))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationForm)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	fps := new(FormParseStruct)
	err := Parse(c, fps, "/test")

	assert.NoError(t, err)

	assert.Equal(t, true, fps.BoolField)
	assert.Equal(t, -42, fps.IntField)
	assert.Equal(t, int8(-8), fps.Int8Field)
	assert.Equal(t, int16(-16), fps.Int16Field)
	assert.Equal(t, int32(-32), fps.Int32Field)
	assert.Equal(t, int64(-64), fps.Int64Field)
	assert.Equal(t, uint(42), fps.UintField)
	assert.Equal(t, uint8(8), fps.Uint8Field)
	assert.Equal(t, uint16(16), fps.Uint16Field)
	assert.Equal(t, uint32(32), fps.Uint32Field)
	assert.Equal(t, uint64(64), fps.Uint64Field)
	assert.InDelta(t, float32(3.14), fps.Float32Field, 0.00001)
	assert.InDelta(t, 3.14159, fps.Float64Field, 0.00000001)
	assert.Equal(t, "hello", fps.StringField)
	assert.Equal(t, time.Date(2023, 5, 1, 15, 4, 5, 0, time.UTC), fps.TimeField)
	assert.Equal(t, []string{"a", "b", "c"}, fps.SliceField)
	assert.Equal(t, map[string]string{"key1": "value1", "key2": "value2"}, fps.MapField)
}

func TestComprehensiveJSONParse(t *testing.T) {
	e := echo.New()

	jsonBody := `{
		"bool_field": true,
		"int_field": -42,
		"int8_field": -8,
		"int16_field": -16,
		"int32_field": -32,
		"int64_field": -64,
		"uint_field": 42,
		"uint8_field": 8,
		"uint16_field": 16,
		"uint32_field": 32,
		"uint64_field": 64,
		"float32_field": 3.14,
		"float64_field": 3.14159,
		"string_field": "hello",
		"time_field": "2023-05-01T15:04:05Z",
		"slice_field": [1, 2, 3, 4, 5],
		"map_field": {"key1": "value1", "key2": "value2"},
		"struct_field": {"nested_field": "nested value"},
		"interface_field": ["any", "type", "of", "data"]
	}`

	req := httptest.NewRequest(http.MethodPost, "/test", strings.NewReader(jsonBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	jps := new(JSONParseStruct)
	err := Parse(c, jps, "/test")

	assert.NoError(t, err)

	assert.Equal(t, true, jps.BoolField)
	assert.Equal(t, -42, jps.IntField)
	assert.Equal(t, int8(-8), jps.Int8Field)
	assert.Equal(t, int16(-16), jps.Int16Field)
	assert.Equal(t, int32(-32), jps.Int32Field)
	assert.Equal(t, int64(-64), jps.Int64Field)
	assert.Equal(t, uint(42), jps.UintField)
	assert.Equal(t, uint8(8), jps.Uint8Field)
	assert.Equal(t, uint16(16), jps.Uint16Field)
	assert.Equal(t, uint32(32), jps.Uint32Field)
	assert.Equal(t, uint64(64), jps.Uint64Field)
	assert.InDelta(t, float32(3.14), jps.Float32Field, 0.00001)
	assert.InDelta(t, 3.14159, jps.Float64Field, 0.00000001)
	assert.Equal(t, "hello", jps.StringField)
	assert.Equal(t, time.Date(2023, 5, 1, 15, 4, 5, 0, time.UTC), jps.TimeField)
	assert.Equal(t, []int{1, 2, 3, 4, 5}, jps.SliceField)
	assert.Equal(t, map[string]string{"key1": "value1", "key2": "value2"}, jps.MapField)
	assert.Equal(t, "nested value", jps.StructField.NestedField)
	assert.Equal(t, []interface{}{"any", "type", "of", "data"}, jps.InterfaceField)
}
