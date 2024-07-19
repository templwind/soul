package util

import (
	"crypto/sha512"
	"encoding/base64"
	"fmt"
	"os"
)

// Function to calculate SRI hash
func CalculateSRI(filename string) (string, error) {
	// Read the file content
	data, err := os.ReadFile(filename)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	// Generate the SHA-384 hash
	sum := sha512.Sum384(data)
	hash := sum[:]

	// Encode the hash in Base64
	sriHash := base64.StdEncoding.EncodeToString(hash)
	return fmt.Sprintf("sha384-%s", sriHash), nil
}
