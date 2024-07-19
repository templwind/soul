package util

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

func CutStringFromMatch(input, pattern string) string {
	fmt.Println(input)
	parts := strings.Split(input, pattern)
	if len(parts) < 2 {
		return input
	}
	return strings.TrimSpace(parts[1])
}

// toCamel converts string to camelCase
func ToCamel(s string) string {
	words := SplitIntoWords(s)
	caser := cases.Title(language.English)
	for i := 1; i < len(words); i++ {
		words[i] = caser.String(words[i])
	}
	return strings.Join(words, "")
}

// toKebab converts string to kebab-case
func ToKebab(s string) string {
	return strings.Join(SplitIntoWords(s), "-")
}

// toTitle converts string to Title Case
func ToTitle(s string) string {
	words := SplitIntoWords(s)
	for i := range words {
		if len(words[i]) > 0 {
			runes := []rune(words[i])
			runes[0] = unicode.ToUpper(runes[0])
			words[i] = string(runes)
		}
	}
	return strings.Join(words, " ")
}

// toSnake converts string to snake_case
func ToSnake(s string) string {
	return strings.Join(SplitIntoWords(s), "_")
}

// toPascal converts string to PascalCase
func ToPascal(s string) string {
	words := SplitIntoWords(s)
	for i := range words {
		words[i] = FirstToUpper(words[i])
	}
	return strings.Join(words, "")
}

// toConstant converts string to CONSTANT_CASE
func ToConstant(s string) string {
	return strings.ToUpper(strings.Join(SplitIntoWords(s), "_"))
}

// SplitIntoWords splits the string into words based on non-alphanumeric characters
func SplitIntoWords(s string) []string {
	return regexp.MustCompile(`[^a-zA-Z0-9]+`).Split(s, -1)
}

func FirstToLower(s string) string {
	if len(s) == 0 {
		return s
	}

	firstRune := []rune(s)[0]
	if unicode.IsUpper(firstRune) {
		firstRune = unicode.ToLower(firstRune)
	}

	return string(firstRune) + s[1:]
}

func FirstToUpper(s string) string {
	if len(s) == 0 {
		return s
	}

	firstRune := []rune(s)[0]
	if unicode.IsLower(firstRune) {
		firstRune = unicode.ToUpper(firstRune)
	}

	return string(firstRune) + s[1:]
}
