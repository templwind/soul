package types

type CardDetails struct {
	CardNumber     string `json:"card_number"`
	ExpiryMonth    int    `json:"expiry_month"`
	ExpiryYear     int    `json:"expiry_year"`
	CVV            string `json:"cvv"`
	CardholderName string `json:"cardholder_name"`
	BillingAddress string `json:"billing_address"`
}