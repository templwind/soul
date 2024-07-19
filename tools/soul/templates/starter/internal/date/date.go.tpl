package date

import (
	"fmt"
	"strings"
	"time"
)

func TimeToString(t time.Time) string {
	const layout = "2006-01-02 15:04:05"
	return t.Format(layout)
}

// ParseDateString parses a date string into a time.Time object
func StringToTime(dateStr string) time.Time {
	const layout = "2006-01-02 15:04:05" // Adjust layout to match your date string format
	t, err := time.Parse(layout, dateStr)
	if err != nil {
		fmt.Printf("Error parsing date: %v\n", err)
		return time.Time{}
	}
	return t
}

// DateFormat formats a time.Time according to a format string
// similar to PHP's date function.
func Format(t time.Time, format string) string {
	replacements := map[string]string{
		// Day
		"d": t.Format("02"),
		"D": t.Format("Mon"),
		"j": t.Format("2"),
		"l": t.Format("Monday"),
		"N": fmt.Sprintf("%d", t.Weekday()+1),
		"S": suffix(t.Day()),
		"w": fmt.Sprintf("%d", t.Weekday()),
		"z": fmt.Sprintf("%d", t.YearDay()-1),

		// Week
		"W": t.Format("02"),

		// Month
		"F": t.Format("January"),
		"m": t.Format("01"),
		"M": t.Format("Jan"),
		"n": t.Format("1"),
		"t": fmt.Sprintf("%d", daysInMonth(t)),

		// Year
		"L": leapYear(t),
		"Y": t.Format("2006"),
		"y": t.Format("06"),

		// Time
		"a": t.Format("pm"),
		"A": t.Format("PM"),
		"g": t.Format("3"),
		"G": t.Format("15"),
		"h": t.Format("03"),
		"H": t.Format("15"),
		"i": t.Format("04"),
		"s": t.Format("05"),

		// Full Date/Time
		"c": t.Format(time.RFC3339),
		"r": t.Format(time.RFC1123Z),
		"U": fmt.Sprintf("%d", t.Unix()),
	}

	var result strings.Builder
	for _, runeValue := range format {
		if repl, ok := replacements[string(runeValue)]; ok {
			result.WriteString(repl)
		} else {
			result.WriteRune(runeValue)
		}
	}

	return result.String()
}

// Helper function to get the suffix of a day
func suffix(day int) string {
	switch day {
	case 1, 21, 31:
		return "st"
	case 2, 22:
		return "nd"
	case 3, 23:
		return "rd"
	default:
		return "th"
	}
}

// Helper function to check if the year is a leap year
func leapYear(t time.Time) string {
	year := t.Year()
	if (year%4 == 0 && year%100 != 0) || year%400 == 0 {
		return "1"
	}
	return "0"
}

// Helper function to get the number of days in a month
func daysInMonth(t time.Time) int {
	month := t.Month()
	year := t.Year()

	switch month {
	case time.April, time.June, time.September, time.November:
		return 30
	case time.February:
		if (year%4 == 0 && year%100 != 0) || year%400 == 0 {
			return 29
		}
		return 28
	default:
		return 31
	}
}
