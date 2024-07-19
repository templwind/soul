package account

import (
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"

	validation "github.com/go-ozzo/ozzo-validation"
	"github.com/go-ozzo/ozzo-validation/is"
)

type UpdateAccountForm struct {
	CompanyName   string `json:"company_name" form:"company_name"`
	Address1      string `json:"address_1" form:"address_1"`
	Address2      string `json:"address_2,omitempty" form:"address_2"`
	City          string `json:"city" form:"city"`
	StateProvince string `json:"state_province" form:"state_province"`
	PostalCode    string `json:"postal_code" form:"postal_code"`
	Country       string `json:"country" form:"country"`
	Phone         string `json:"phone" form:"phone"`
	Email         string `json:"email,omitempty" form:"email"`
	Website       string `json:"website,omitempty" form:"website"`
}

func (f *UpdateAccountForm) Validate() error {
	return validation.ValidateStruct(f,
		validation.Field(&f.CompanyName,
			validation.Required.Error("Company name is required"),
			validation.Length(1, 100).Error("Company name must be between 1 and 100 characters long"),
		),
		validation.Field(&f.Address1,
			validation.Required.Error("Address line 1 is required"),
			validation.Length(1, 100).Error("Address line 1 must be between 1 and 100 characters long"),
		),
		validation.Field(&f.Address2,
			validation.Length(0, 100).Error("Address line 2 must be less than 100 characters"),
		),
		validation.Field(&f.City,
			validation.Required.Error("City is required"),
			validation.Length(1, 50).Error("City must be between 1 and 50 characters long"),
		),
		validation.Field(&f.StateProvince,
			validation.Required.Error("State/Province is required"),
			validation.Length(1, 50).Error("State/Province must be between 1 and 50 characters long"),
		),
		validation.Field(&f.PostalCode,
			validation.Required.Error("Postal code is required"),
			validation.Length(1, 20).Error("Postal code must be between 1 and 20 characters long"),
		),
		validation.Field(&f.Country,
			validation.Required.Error("Country is required"),
			validation.Length(1, 50).Error("Country must be between 1 and 50 characters long"),
		),
		validation.Field(&f.Phone,
			validation.Required.Error("Phone number is required"),
			// is.E164.Error("Invalid phone number format"),
		),
		validation.Field(&f.Email,
			validation.NilOrNotEmpty.Error("Email must not be empty if provided"),
			is.Email.Error("Invalid email format"),
		),
		validation.Field(&f.Website,
			validation.Length(0, 100).Error("Website must be less than 100 characters"),
			is.URL.Error("Invalid website URL"),
		),
	)
}

func (f *UpdateAccountForm) ToModel(account *models.Account) {
	if f.CompanyName != "" {
		account.CompanyName = types.NewNullString(f.CompanyName)
	}
	if f.Address1 != "" {
		account.Address1 = types.NewNullString(f.Address1)
	}
	if f.Address2 != "" {
		account.Address2 = types.NewNullString(f.Address2)
	}
	if f.City != "" {
		account.City = types.NewNullString(f.City)
	}
	if f.StateProvince != "" {
		account.StateProvince = types.NewNullString(f.StateProvince)
	}
	if f.PostalCode != "" {
		account.PostalCode = types.NewNullString(f.PostalCode)
	}
	if f.Country != "" {
		account.Country = types.NewNullString(f.Country)
	}
	if f.Phone != "" {
		account.Phone = types.NewNullString(f.Phone)
	}
	if f.Email != "" {
		account.Email = types.NewNullString(f.Email)
	}
	if f.Website != "" {
		account.Website = types.NewNullString(f.Website)
	}
}
