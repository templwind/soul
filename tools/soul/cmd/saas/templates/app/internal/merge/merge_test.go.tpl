package merge

import (
	"database/sql"
	"testing"
	"time"

	"{{ .serviceName }}/internal/types" // Update with the actual package path

	"github.com/stretchr/testify/assert"
)

type AccountInfoForm struct {
	CompanyName   string `form:"company_name"`
	Address1      string `form:"address_1"`
	Address2      string `form:"address_2"`
	City          string `form:"city"`
	StateProvince string `form:"state_province"`
	PostalCode    string `form:"postal_code"`
	Phone         string `form:"phone"`
	Website       string `form:"website"`
}

type Account struct {
	ID            string         `db:"id"`
	CompanyName   sql.NullString `db:"company_name"`
	Address1      sql.NullString `db:"address_1"`
	Address2      sql.NullString `db:"address_2"`
	City          sql.NullString `db:"city"`
	StateProvince sql.NullString `db:"state_province"`
	PostalCode    sql.NullString `db:"postal_code"`
	Country       sql.NullString `db:"country"`
	Phone         sql.NullString `db:"phone"`
	Email         sql.NullString `db:"email"`
	Website       sql.NullString `db:"website"`
	PrimaryUserID string         `db:"primary_user_id"`
	CreatedAt     sql.NullTime   `db:"created_at"`
	UpdatedAt     sql.NullTime   `db:"updated_at"`
}

func TestMergeStructs(t *testing.T) {
	form := AccountInfoForm{
		CompanyName:   "New Company",
		Address1:      "123 New Address",
		Address2:      "",
		City:          "New City",
		StateProvince: "New State",
		PostalCode:    "12345",
		Phone:         "",
		Website:       "http://newwebsite.com",
	}

	db := &Account{
		ID:            "1",
		CompanyName:   sql.NullString{String: "Old Company", Valid: true},
		Address1:      sql.NullString{String: "Old Address", Valid: true},
		Address2:      sql.NullString{String: "Old Address2", Valid: true},
		City:          sql.NullString{String: "Old City", Valid: true},
		StateProvince: sql.NullString{String: "Old State", Valid: true},
		PostalCode:    sql.NullString{String: "54321", Valid: true},
		Country:       sql.NullString{String: "Old Country", Valid: true},
		Phone:         sql.NullString{String: "1234567890", Valid: true},
		Email:         sql.NullString{String: "old@example.com", Valid: true},
		Website:       sql.NullString{String: "http://oldwebsite.com", Valid: true},
		PrimaryUserID: "2",
		CreatedAt:     sql.NullTime{Time: time.Now(), Valid: true},
		UpdatedAt:     sql.NullTime{Time: time.Now(), Valid: true},
	}

	err := New(form, db)
	assert.NoError(t, err)

	assert.Equal(t, "1", db.ID)
	assert.Equal(t, types.NewNullString("New Company"), db.CompanyName)
	assert.Equal(t, types.NewNullString("123 New Address"), db.Address1)
	assert.Equal(t, types.NewNullString("Old Address2"), db.Address2)
	assert.Equal(t, types.NewNullString("New City"), db.City)
	assert.Equal(t, types.NewNullString("New State"), db.StateProvince)
	assert.Equal(t, types.NewNullString("12345"), db.PostalCode)
	assert.Equal(t, types.NewNullString("Old Country"), db.Country)
	assert.Equal(t, types.NewNullString("1234567890"), db.Phone)
	assert.Equal(t, types.NewNullString("old@example.com"), db.Email)
	assert.Equal(t, types.NewNullString("http://newwebsite.com"), db.Website)
}
