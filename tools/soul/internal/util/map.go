package util

// CopyMap creates a shallow copy of a map[string]string
func CopyMap(original map[string]any) map[string]any {
	copied := make(map[string]any)
	for key, value := range original {
		copied[key] = value
	}
	return copied
}
