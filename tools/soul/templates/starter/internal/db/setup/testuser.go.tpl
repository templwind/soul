package setup

import (
	"context"
	"database/sql"
	"fmt"

	"{{ .ModuleName }}/internal/models"
)

func (s *Setup) CreateTestUser(ctx context.Context, db *sql.DB) error {
	bdb := s.boostDB(db)

	user := &models.User{
		ID:       s.testUserID,
		Name:     s.c.Setup.TestUser.Name,
		Username: s.c.Setup.TestUser.Username,
		Email:    s.c.Setup.TestUser.Email,
		TypeID:   models.USER_TYPE_MASTER_USER,
		Verified: true,
	}

	fmt.Printf("Creating User: %+v\n", s.c.Setup.TestUser)
	if err := user.InsertWithPassword(ctx, bdb, s.c.Setup.TestUser.Password); err != nil {
		return err
	}

	// link the user to the accounts
	{
		ua := &models.UserAccount{
			UserID:    s.testUserID,
			AccountID: s.account1ID,
		}
		ua.Insert(ctx, bdb)
	}
	{
		ua := &models.UserAccount{
			UserID:    s.testUserID,
			AccountID: s.account2ID,
		}
		ua.Insert(ctx, bdb)
	}
	return nil
}

func (s *Setup) TearDownTestUser(ctx context.Context, db *sql.DB) error {
	return nil
}
