package changepassword

import (
	"regexp"

	validation "github.com/go-ozzo/ozzo-validation"
)

var (
	letterRegexp      = regexp.MustCompile(`[A-Za-z]`)
	digitRegexp       = regexp.MustCompile(`\d`)
	specialCharRegexp = regexp.MustCompile(`[@$!%*#?&]`)
)

type ChangePasswordForm struct {
	CurrentPassword string `form:"password"`
	NewPassword     string `form:"new_password"`
	ConfirmPassword string `form:"confirm_password"`
}

func (f *ChangePasswordForm) Validate() error {
	return validation.ValidateStruct(f,
		validation.Field(&f.NewPassword,
			validation.Required.Error("New password is required"),
			validation.Length(8, 50).Error("New password must be between 8 and 50 characters long"),
			validation.Match(letterRegexp).Error("New password must include at least one letter"),
			validation.Match(digitRegexp).Error("New password must include at least one digit"),
			validation.Match(specialCharRegexp).Error("New password must include at least one special character"),
		),
		validation.Field(&f.ConfirmPassword,
			validation.Required.Error("Confirm password is required"),
			validation.In(f.NewPassword).Error("Passwords do not match"),
		),
	)
}
