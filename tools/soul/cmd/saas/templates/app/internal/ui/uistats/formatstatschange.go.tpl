package uistats

import (
	"fmt"

	"github.com/dustin/go-humanize"
)

// FormatChangeGeneric calculates and formats the change between current and previous values.
// It supports both integer and floating-point types.
func FormatChangeGeneric[T float64 | int64](current, previous T) string {
	var arrow string
	var percentage float64
	var change float64

	// Convert both current and previous to float64 for uniform calculations
	currentF := toFloat64(current)
	previousF := toFloat64(previous)
	change = currentF - previousF

	// Determine the arrow and percentage change
	if previousF == 0 {
		// Avoid division by zero
		if change > 0 {
			arrow = "↗︎"
			percentage = 100.0 // Arbitrary, since previous is 0
		} else if change < 0 {
			arrow = "↘︎"
			percentage = -100.0
		} else {
			arrow = ""
			percentage = 0.0
		}
	} else {
		percentage = (change / previousF) * 100
		if change > 0 {
			arrow = "↗︎"
		} else if change < 0 {
			arrow = "↘︎"
		} else {
			arrow = ""
		}
	}

	var formattedChange string
	if isFloat(current) {
		formattedChange = fmt.Sprintf("%.2f%%", change)
	} else {
		// For integer types, format with commas
		formattedChange = humanize.Comma(int64(change))
	}

	// Format the percentage with two decimal places
	formattedPercentage := fmt.Sprintf("%.2f%%", percentage)

	// Combine everything
	if arrow != "" {
		return fmt.Sprintf("%s %s (%s)", arrow, formattedChange, formattedPercentage)
	}
	return fmt.Sprintf("%s (%s)", formattedChange, formattedPercentage)
}

// toFloat64 converts a generic type (float64 or int64) to float64.
func toFloat64[T float64 | int64](value T) float64 {
	switch v := any(value).(type) {
	case float64:
		return v
	case int64:
		return float64(v)
	default:
		return 0.0
	}
}

// isFloat checks if the generic type is float64.
func isFloat[T float64 | int64](value T) bool {
	switch any(value).(type) {
	case float64:
		return true
	default:
		return false
	}
}
