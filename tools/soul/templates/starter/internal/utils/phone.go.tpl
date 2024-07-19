package utils

import (
	"github.com/nyaruka/phonenumbers"
)

func FormatPhone(phone, countryCode string) string {
	// parse our phone number
	num, err := phonenumbers.Parse(phone, countryCode)
	if err != nil {
		return phone
	}

	// format it using national format
	return phonenumbers.Format(num, phonenumbers.NATIONAL)
}
