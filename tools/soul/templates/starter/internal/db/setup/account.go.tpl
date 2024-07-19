package setup

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"{{ .ModuleName }}/internal/date"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"
)

func (s *Setup) CreateDefaultAccount(ctx context.Context, db *sql.DB) error {
	bdb := s.boostDB(db)

	// create 2 accounts for testing
	{
		account := &models.Account{
			ID:            s.account1ID,
			PrimaryUserID: s.testUserID,
			CompanyName:   types.NewNullString("Test Account #1"),
			Address1:      types.NewNullString("1234 Elm St."),
			Address2:      types.NewNullString("Suite 100"),
			City:          types.NewNullString("Springfield"),
			StateProvince: types.NewNullString("IL"),
			PostalCode:    types.NewNullString("62701"),
			Phone:         types.NewNullString("217-555-1212"),
			Country:       types.NewNullString("US"),
			Email:         types.NewNullString("support@exmaple.com"),
			Website:       types.NewNullString("https://exmaple.com"),
			CreatedAt:     date.TimeToString(time.Now()),
			UpdatedAt:     date.TimeToString(time.Now()),
		}

		fmt.Printf("Creating Account: %+v\n", account.CompanyName)
		account.Insert(ctx, bdb)
	}

	account := &models.Account{
		ID:            s.account2ID,
		PrimaryUserID: s.testUserID,
		CompanyName:   types.NewNullString("Test Account #2"),
		Address1:      types.NewNullString("1234 Elm St."),
		Address2:      types.NewNullString("Suite 100"),
		City:          types.NewNullString("Springfield"),
		StateProvince: types.NewNullString("IL"),
		PostalCode:    types.NewNullString("62701"),
		Country:       types.NewNullString("US"),
		Phone:         types.NewNullString("217-555-1212"),
		Email:         types.NewNullString("support@exmaple.com"),
		Website:       types.NewNullString("https://exmaple.com"),
		CreatedAt:     date.TimeToString(time.Now()),
		UpdatedAt:     date.TimeToString(time.Now()),
	}

	fmt.Printf("Creating Account: %+v\n", account.CompanyName)
	return account.Insert(ctx, bdb)

}

func (s *Setup) TearDownDefaultAccount(ctx context.Context, db *sql.DB) error {
	return nil
}
