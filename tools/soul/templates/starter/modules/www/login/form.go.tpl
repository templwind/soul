package login

import (
	"regexp"

	validation "github.com/go-ozzo/ozzo-validation"
	"github.com/go-ozzo/ozzo-validation/is"
)

var (
	letterRegexp      = regexp.MustCompile(`[A-Za-z]`)
	digitRegexp       = regexp.MustCompile(`\d`)
	specialCharRegexp = regexp.MustCompile(`[@$!%*#?&0]`)
)

type LoginForm struct {
	Email    string `form:"email"`
	Password string `form:"password"`
}

func (f *LoginForm) Validate() error {
	return validation.ValidateStruct(f,
		// Validate the email field: it must not be empty and must be a valid email format.
		validation.Field(&f.Email,
			validation.Required.Error("Email is required"),
			is.Email.Error("Invalid email format"),
		),

		// Validate the password field: it must meet several criteria.
		validation.Field(&f.Password,
			validation.Required.Error("is required"),
			validation.Length(8, 50).Error("Password must be between 8 and 50 characters long"),
			validation.Match(letterRegexp).Error("Password must include at least one letter"),
			validation.Match(digitRegexp).Error("Password must include at least one digit"),
			validation.Match(specialCharRegexp).Error("Password must include at least one special character"),
		),
	)
}
