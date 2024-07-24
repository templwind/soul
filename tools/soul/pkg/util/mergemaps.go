package util

// Helper function to merge maps
func MergeMaps(original, additional map[string]string) map[string]string {
	merged := make(map[string]string)
	for key, value := range original {
		merged[key] = value
	}
	for key, value := range additional {
		merged[key] = value
	}
	return merged
}
