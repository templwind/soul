package models

import (
	"context"
	"fmt"
	"time"

	"{{ .ModuleName }}/internal/security"
	
	"golang.org/x/crypto/bcrypt"
)

func (u *User) ValidatePassword(password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)) == nil
}

func (u *User) InsertWithPassword(ctx context.Context, db SqlxDB, password string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		return err
	}

	if u.ID == "" {
		u.ID = NewID(db, "u")
	}

	u.PasswordHash = string(hash)
	u.TokenKey = security.RandomString(50)
	u.CreatedAt = time.Now().Format("2006-01-02 15:04:05")
	u.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

	err = u.Insert(ctx, db)
	if err != nil {
		fmt.Println("Error inserting user: ", err)
		return err
	}
	return nil
}

func (u *User) UpdateWithPassword(ctx context.Context, db SqlxDB, password string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		return err
	}

	if u.ID == "" {
		return fmt.Errorf("User ID is required")
	}

	u.PasswordHash = string(hash)
	u.TokenKey = security.RandomString(50)
	u.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

	err = u.Update(ctx, db)
	if err != nil {
		fmt.Println("Error updating user: ", err)
		return err
	}
	return nil
}
