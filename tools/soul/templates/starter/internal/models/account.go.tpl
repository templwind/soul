package models

import (
	"context"
	"fmt"
	"regexp"

	validation "github.com/go-ozzo/ozzo-validation"
)

func (f *Account) Validate() error {
	letterRegexp := regexp.MustCompile(`[A-Za-z]`)
	return validation.ValidateStruct(f,
		// Validate the name field: it must not be empty.
		validation.Field(&f.CompanyName,
			validation.Required.Error("Company name is required"),
			validation.Length(2, 100).Error("Company name must be between 2 and 100 characters long"),
			validation.Match(letterRegexp).Error("Company name must include at least one letter"),
		),
	)
}

func FindAllAccountsByUserID(ctx context.Context, db SqlxDB, userID string, page int, pageSize int) ([]*Account, error) {
	var query string
	if pageSize == 0 {
		query = fmt.Sprintf(`
		SELECT %s 
		FROM %s
		INNER JOIN user_accounts ON accounts.id = user_accounts.account_id
		WHERE user_accounts.user_id = $1
		ORDER BY accounts.company_name ASC
		`, AccountRows, AccountTableName)
	} else {
		offset := (page - 1) * pageSize
		query = fmt.Sprintf(`
		SELECT %s 
		FROM %s 
		INNER JOIN user_accounts ON accounts.id = user_accounts.account_id
		WHERE user_accounts.user_id = $1
		ORDER BY accounts.company_name ASC
		LIMIT %d OFFSET %d`, AccountRows, AccountTableName, pageSize, offset)
	}

	var results []*Account
	err := db.SelectContext(ctx, &results, query, userID)
	if err != nil {
		return nil, err
	}
	return results, nil
}
