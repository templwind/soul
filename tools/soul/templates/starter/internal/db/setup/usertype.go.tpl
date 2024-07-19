package setup

import (
	"context"
	"database/sql"
	"fmt"

	"{{ .ModuleName }}/internal/models"
)

func (s *Setup) CreateUserTypes(ctx context.Context, db *sql.DB) error {
	bdb := s.boostDB(db)

	userTypes := []*models.UserType{
		{
			ID:          models.USER_TYPE_SUPER_ADMIN,
			TypeName:    "Super Admin",
			Description: "Super Admin Users - Has complete control over all platform management functions.",
		},
		{
			ID:          models.USER_TYPE_COMPANY_USER,
			TypeName:    "Company User",
			Description: "Company Users - Has access to specific administrative functions necessary for company operations.",
		},
		{
			ID:          models.USER_TYPE_MASTER_USER,
			TypeName:    "Master User",
			Description: "Master Users - A user with elevated privileges within the context of service usage.",
		},
		{
			ID:          models.USER_TYPE_SERVICE_USER,
			TypeName:    "Service User",
			Description: "Service Users - Regular users of the service with standard user-level access and capabilities.",
		},
	}

	for _, userType := range userTypes {
		fmt.Printf("Creating UserType: %+v\n", userType)
		if err := userType.Insert(ctx, bdb); err != nil {
			return err
		}
	}

	return nil
}

func (s *Setup) TearDownUserTypes(ctx context.Context, db *sql.DB) error {
	bdb := s.boostDB(db)

	user, _ := models.UserByEmail(ctx, bdb, s.c.Setup.TestUser.Email)
	return user.Delete(ctx, bdb)
}
