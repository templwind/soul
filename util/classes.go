package util

import "strings"

// mergeClasses merges default classes with optionally provided overrides or additions.
func MergeClasses(baseClasses, additionalClasses string) string {
	if additionalClasses == "" {
		return baseClasses
	}
	baseSet := make(map[string]struct{})
	for _, class := range strings.Fields(baseClasses) {
		baseSet[class] = struct{}{}
	}
	// Add or override classes
	for _, class := range strings.Fields(additionalClasses) {
		baseSet[class] = struct{}{}
	}
	var result []string
	for class := range baseSet {
		result = append(result, class)
	}
	return strings.Join(result, " ")
}
