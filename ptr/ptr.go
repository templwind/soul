package ptr

import "time"

// Value dereferences a pointer and returns its value.
// If the pointer is nil, it returns the specified defaultValue.
func Value[T any](p *T, defaultValue T) T {
	if p == nil {
		return defaultValue
	}
	return *p
}

// ToPointer converts a value of type T to a pointer.
func ToPointer[T any](v T) *T {
	return &v
}

// SliceValue converts a slice of pointers to a slice of values.
// If a pointer in the slice is nil, defaultValue is used for that element.
// Returns nil if input slice is nil.
func SliceValue[T any](p []*T, defaultValue T) []T {
	if p == nil {
		return nil
	}
	result := make([]T, len(p))
	for i, v := range p {
		result[i] = Value(v, defaultValue)
	}
	return result
}

// NonNilSliceValue is like SliceValue but returns empty slice instead of nil for nil input.
func NonNilSliceValue[T any](p []*T, defaultValue T) []T {
	if p == nil {
		return []T{}
	}
	return SliceValue(p, defaultValue)
}

// ToSlicePointer converts a slice of values to a slice of pointers.
// Returns nil if input slice is nil.
func ToSlicePointer[T any](v []T) []*T {
	if v == nil {
		return nil
	}
	result := make([]*T, len(v))
	for i, item := range v {
		result[i] = ToPointer(item)
	}
	return result
}

// Zero values for complex types
func zeroTime() time.Time         { return time.Time{} }
func zeroDuration() time.Duration { return time.Duration(0) }

// String returns the value of a string pointer or empty string if nil.
func String(p *string) string { return Value(p, "") }

// Int returns the value of an int pointer or 0 if nil.
func Int(p *int) int { return Value(p, 0) }

// Int8 returns the value of an int8 pointer or 0 if nil.
func Int8(p *int8) int8 { return Value(p, 0) }

// Int16 returns the value of an int16 pointer or 0 if nil.
func Int16(p *int16) int16 { return Value(p, 0) }

// Int32 returns the value of an int32 pointer or 0 if nil.
func Int32(p *int32) int32 { return Value(p, 0) }

// Int64 returns the value of an int64 pointer or 0 if nil.
func Int64(p *int64) int64 { return Value(p, 0) }

// Uint returns the value of a uint pointer or 0 if nil.
func Uint(p *uint) uint { return Value(p, 0) }

// Uint8 returns the value of a uint8 pointer or 0 if nil.
func Uint8(p *uint8) uint8 { return Value(p, 0) }

// Uint16 returns the value of a uint16 pointer or 0 if nil.
func Uint16(p *uint16) uint16 { return Value(p, 0) }

// Uint32 returns the value of a uint32 pointer or 0 if nil.
func Uint32(p *uint32) uint32 { return Value(p, 0) }

// Uint64 returns the value of a uint64 pointer or 0 if nil.
func Uint64(p *uint64) uint64 { return Value(p, 0) }

// Float32 returns the value of a float32 pointer or 0.0 if nil.
func Float32(p *float32) float32 { return Value(p, 0.0) }

// Float64 returns the value of a float64 pointer or 0.0 if nil.
func Float64(p *float64) float64 { return Value(p, 0.0) }

// Bool returns the value of a bool pointer or false if nil.
func Bool(p *bool) bool { return Value(p, false) }

// Complex64 returns the value of a complex64 pointer or 0+0i if nil.
func Complex64(p *complex64) complex64 { return Value(p, 0) }

// Complex128 returns the value of a complex128 pointer or 0+0i if nil.
func Complex128(p *complex128) complex128 { return Value(p, 0) }

// Byte returns the value of a byte pointer or 0 if nil.
func Byte(p *byte) byte { return Value(p, 0) }

// Rune returns the value of a rune pointer or 0 if nil.
func Rune(p *rune) rune { return Value(p, 0) }

// Duration returns the value of a time.Duration pointer or zero duration if nil.
func Duration(p *time.Duration) time.Duration { return Value(p, zeroDuration()) }

// Time returns the value of a time.Time pointer or zero time if nil.
func Time(p *time.Time) time.Time { return Value(p, zeroTime()) }

// ToString converts a string to a string pointer.
func ToString(v string) *string { return ToPointer(v) }

// ToInt converts an int to an int pointer.
func ToInt(v int) *int { return ToPointer(v) }

// ToInt8 converts an int8 to an int8 pointer.
func ToInt8(v int8) *int8 { return ToPointer(v) }

// ToInt16 converts an int16 to an int16 pointer.
func ToInt16(v int16) *int16 { return ToPointer(v) }

// ToInt32 converts an int32 to an int32 pointer.
func ToInt32(v int32) *int32 { return ToPointer(v) }

// ToInt64 converts an int64 to an int64 pointer.
func ToInt64(v int64) *int64 { return ToPointer(v) }

// ToUint converts a uint to a uint pointer.
func ToUint(v uint) *uint { return ToPointer(v) }

// ToUint8 converts a uint8 to a uint8 pointer.
func ToUint8(v uint8) *uint8 { return ToPointer(v) }

// ToUint16 converts a uint16 to a uint16 pointer.
func ToUint16(v uint16) *uint16 { return ToPointer(v) }

// ToUint32 converts a uint32 to a uint32 pointer.
func ToUint32(v uint32) *uint32 { return ToPointer(v) }

// ToUint64 converts a uint64 to a uint64 pointer.
func ToUint64(v uint64) *uint64 { return ToPointer(v) }

// ToFloat32 converts a float32 to a float32 pointer.
func ToFloat32(v float32) *float32 { return ToPointer(v) }

// ToFloat64 converts a float64 to a float64 pointer.
func ToFloat64(v float64) *float64 { return ToPointer(v) }

// ToBool converts a bool to a bool pointer.
func ToBool(v bool) *bool { return ToPointer(v) }

// ToComplex64 converts a complex64 to a complex64 pointer.
func ToComplex64(v complex64) *complex64 { return ToPointer(v) }

// ToComplex128 converts a complex128 to a complex128 pointer.
func ToComplex128(v complex128) *complex128 { return ToPointer(v) }

// ToByte converts a byte to a byte pointer.
func ToByte(v byte) *byte { return ToPointer(v) }

// ToRune converts a rune to a rune pointer.
func ToRune(v rune) *rune { return ToPointer(v) }

// ToDuration converts a time.Duration to a time.Duration pointer.
func ToDuration(v time.Duration) *time.Duration { return ToPointer(v) }

// ToTime converts a time.Time to a time.Time pointer.
func ToTime(v time.Time) *time.Time { return ToPointer(v) }

// StringSlice converts a slice of string pointers to a slice of strings.
// Nil pointers are converted to empty strings. Returns nil for nil input.
func StringSlice(p []*string) []string { return SliceValue(p, "") }

// IntSlice converts a slice of int pointers to a slice of ints.
// Nil pointers are converted to 0. Returns nil for nil input.
func IntSlice(p []*int) []int { return SliceValue(p, 0) }

// Int8Slice converts a slice of int8 pointers to a slice of int8s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Int8Slice(p []*int8) []int8 { return SliceValue(p, 0) }

// Int16Slice converts a slice of int16 pointers to a slice of int16s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Int16Slice(p []*int16) []int16 { return SliceValue(p, 0) }

// Int32Slice converts a slice of int32 pointers to a slice of int32s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Int32Slice(p []*int32) []int32 { return SliceValue(p, 0) }

// Int64Slice converts a slice of int64 pointers to a slice of int64s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Int64Slice(p []*int64) []int64 { return SliceValue(p, 0) }

// UintSlice converts a slice of uint pointers to a slice of uints.
// Nil pointers are converted to 0. Returns nil for nil input.
func UintSlice(p []*uint) []uint { return SliceValue(p, 0) }

// Uint8Slice converts a slice of uint8 pointers to a slice of uint8s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Uint8Slice(p []*uint8) []uint8 { return SliceValue(p, 0) }

// Uint16Slice converts a slice of uint16 pointers to a slice of uint16s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Uint16Slice(p []*uint16) []uint16 { return SliceValue(p, 0) }

// Uint32Slice converts a slice of uint32 pointers to a slice of uint32s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Uint32Slice(p []*uint32) []uint32 { return SliceValue(p, 0) }

// Uint64Slice converts a slice of uint64 pointers to a slice of uint64s.
// Nil pointers are converted to 0. Returns nil for nil input.
func Uint64Slice(p []*uint64) []uint64 { return SliceValue(p, 0) }

// Float32Slice converts a slice of float32 pointers to a slice of float32s.
// Nil pointers are converted to 0.0. Returns nil for nil input.
func Float32Slice(p []*float32) []float32 { return SliceValue(p, 0.0) }

// Float64Slice converts a slice of float64 pointers to a slice of float64s.
// Nil pointers are converted to 0.0. Returns nil for nil input.
func Float64Slice(p []*float64) []float64 { return SliceValue(p, 0.0) }

// BoolSlice converts a slice of bool pointers to a slice of bools.
// Nil pointers are converted to false. Returns nil for nil input.
func BoolSlice(p []*bool) []bool { return SliceValue(p, false) }

// Complex64Slice converts a slice of complex64 pointers to a slice of complex64s.
// Nil pointers are converted to 0+0i. Returns nil for nil input.
func Complex64Slice(p []*complex64) []complex64 { return SliceValue(p, 0) }

// Complex128Slice converts a slice of complex128 pointers to a slice of complex128s.
// Nil pointers are converted to 0+0i. Returns nil for nil input.
func Complex128Slice(p []*complex128) []complex128 { return SliceValue(p, 0) }

// ByteSlice converts a slice of byte pointers to a slice of bytes.
// Nil pointers are converted to 0. Returns nil for nil input.
func ByteSlice(p []*byte) []byte { return SliceValue(p, 0) }

// RuneSlice converts a slice of rune pointers to a slice of runes.
// Nil pointers are converted to 0. Returns nil for nil input.
func RuneSlice(p []*rune) []rune { return SliceValue(p, 0) }

// DurationSlice converts a slice of time.Duration pointers to a slice of time.Durations.
// Nil pointers are converted to zero duration. Returns nil for nil input.
func DurationSlice(p []*time.Duration) []time.Duration { return SliceValue(p, zeroDuration()) }

// TimeSlice converts a slice of time.Time pointers to a slice of time.Times.
// Nil pointers are converted to zero time. Returns nil for nil input.
func TimeSlice(p []*time.Time) []time.Time { return SliceValue(p, zeroTime()) }

// ToStringSlice converts a slice of strings to a slice of string pointers.
// Returns nil if input slice is nil.
func ToStringSlice(v []string) []*string { return ToSlicePointer(v) }

// ToIntSlice converts a slice of ints to a slice of int pointers.
// Returns nil if input slice is nil.
func ToIntSlice(v []int) []*int { return ToSlicePointer(v) }

// ToInt8Slice converts a slice of int8s to a slice of int8 pointers.
// Returns nil if input slice is nil.
func ToInt8Slice(v []int8) []*int8 { return ToSlicePointer(v) }

// ToInt16Slice converts a slice of int16s to a slice of int16 pointers.
// Returns nil if input slice is nil.
func ToInt16Slice(v []int16) []*int16 { return ToSlicePointer(v) }

// ToInt32Slice converts a slice of int32s to a slice of int32 pointers.
// Returns nil if input slice is nil.
func ToInt32Slice(v []int32) []*int32 { return ToSlicePointer(v) }

// ToInt64Slice converts a slice of int64s to a slice of int64 pointers.
// Returns nil if input slice is nil.
func ToInt64Slice(v []int64) []*int64 { return ToSlicePointer(v) }

// ToUintSlice converts a slice of uints to a slice of uint pointers.
// Returns nil if input slice is nil.
func ToUintSlice(v []uint) []*uint { return ToSlicePointer(v) }

// ToUint8Slice converts a slice of uint8s to a slice of uint8 pointers.
// Returns nil if input slice is nil.
func ToUint8Slice(v []uint8) []*uint8 { return ToSlicePointer(v) }

// ToUint16Slice converts a slice of uint16s to a slice of uint16 pointers.
// Returns nil if input slice is nil.
func ToUint16Slice(v []uint16) []*uint16 { return ToSlicePointer(v) }

// ToUint32Slice converts a slice of uint32s to a slice of uint32 pointers.
// Returns nil if input slice is nil.
func ToUint32Slice(v []uint32) []*uint32 { return ToSlicePointer(v) }

// ToUint64Slice converts a slice of uint64s to a slice of uint64 pointers.
// Returns nil if input slice is nil.
func ToUint64Slice(v []uint64) []*uint64 { return ToSlicePointer(v) }

// ToFloat32Slice converts a slice of float32s to a slice of float32 pointers.
// Returns nil if input slice is nil.
func ToFloat32Slice(v []float32) []*float32 { return ToSlicePointer(v) }

// ToFloat64Slice converts a slice of float64s to a slice of float64 pointers.
// Returns nil if input slice is nil.
func ToFloat64Slice(v []float64) []*float64 { return ToSlicePointer(v) }

// ToBoolSlice converts a slice of bools to a slice of bool pointers.
// Returns nil if input slice is nil.
func ToBoolSlice(v []bool) []*bool { return ToSlicePointer(v) }

// ToComplex64Slice converts a slice of complex64s to a slice of complex64 pointers.
// Returns nil if input slice is nil.
func ToComplex64Slice(v []complex64) []*complex64 { return ToSlicePointer(v) }

// ToComplex128Slice converts a slice of complex128s to a slice of complex128 pointers.
// Returns nil if input slice is nil.
func ToComplex128Slice(v []complex128) []*complex128 { return ToSlicePointer(v) }

// ToByteSlice converts a slice of bytes to a slice of byte pointers.
// Returns nil if input slice is nil.
func ToByteSlice(v []byte) []*byte { return ToSlicePointer(v) }

// ToRuneSlice converts a slice of runes to a slice of rune pointers.
// Returns nil if input slice is nil.
func ToRuneSlice(v []rune) []*rune { return ToSlicePointer(v) }

// ToDurationSlice converts a slice of time.Durations to a slice of time.Duration pointers.
// Returns nil if input slice is nil.
func ToDurationSlice(v []time.Duration) []*time.Duration { return ToSlicePointer(v) }

// ToTimeSlice converts a slice of time.Times to a slice of time.Time pointers.
// Returns nil if input slice is nil.
func ToTimeSlice(v []time.Time) []*time.Time { return ToSlicePointer(v) }

// NonNilStringSlice is like StringSlice but returns empty slice instead of nil for nil input.
func NonNilStringSlice(p []*string) []string { return NonNilSliceValue(p, "") }

// NonNilIntSlice is like IntSlice but returns empty slice instead of nil for nil input.
func NonNilIntSlice(p []*int) []int { return NonNilSliceValue(p, 0) }

// NonNilInt8Slice is like Int8Slice but returns empty slice instead of nil for nil input.
func NonNilInt8Slice(p []*int8) []int8 { return NonNilSliceValue(p, 0) }

// NonNilInt16Slice is like Int16Slice but returns empty slice instead of nil for nil input.
func NonNilInt16Slice(p []*int16) []int16 { return NonNilSliceValue(p, 0) }

// NonNilInt32Slice is like Int32Slice but returns empty slice instead of nil for nil input.
func NonNilInt32Slice(p []*int32) []int32 { return NonNilSliceValue(p, 0) }

// NonNilInt64Slice is like Int64Slice but returns empty slice instead of nil for nil input.
func NonNilInt64Slice(p []*int64) []int64 { return NonNilSliceValue(p, 0) }

// NonNilUintSlice is like UintSlice but returns empty slice instead of nil for nil input.
func NonNilUintSlice(p []*uint) []uint { return NonNilSliceValue(p, 0) }

// NonNilUint8Slice is like Uint8Slice but returns empty slice instead of nil for nil input.
func NonNilUint8Slice(p []*uint8) []uint8 { return NonNilSliceValue(p, 0) }

// NonNilUint16Slice is like Uint16Slice but returns empty slice instead of nil for nil input.
func NonNilUint16Slice(p []*uint16) []uint16 { return NonNilSliceValue(p, 0) }

// NonNilUint32Slice is like Uint32Slice but returns empty slice instead of nil for nil input.
func NonNilUint32Slice(p []*uint32) []uint32 { return NonNilSliceValue(p, 0) }

// NonNilUint64Slice is like Uint64Slice but returns empty slice instead of nil for nil input.
func NonNilUint64Slice(p []*uint64) []uint64 { return NonNilSliceValue(p, 0) }

// NonNilFloat32Slice is like Float32Slice but returns empty slice instead of nil for nil input.
func NonNilFloat32Slice(p []*float32) []float32 { return NonNilSliceValue(p, 0.0) }

// NonNilFloat64Slice is like Float64Slice but returns empty slice instead of nil for nil input.
func NonNilFloat64Slice(p []*float64) []float64 { return NonNilSliceValue(p, 0.0) }

// NonNilBoolSlice is like BoolSlice but returns empty slice instead of nil for nil input.
func NonNilBoolSlice(p []*bool) []bool { return NonNilSliceValue(p, false) }

// NonNilComplex64Slice is like Complex64Slice but returns empty slice instead of nil for nil input.
func NonNilComplex64Slice(p []*complex64) []complex64 { return NonNilSliceValue(p, 0) }

// NonNilComplex128Slice is like Complex128Slice but returns empty slice instead of nil for nil input.
func NonNilComplex128Slice(p []*complex128) []complex128 { return NonNilSliceValue(p, 0) }

// NonNilByteSlice is like ByteSlice but returns empty slice instead of nil for nil input.
func NonNilByteSlice(p []*byte) []byte { return NonNilSliceValue(p, 0) }

// NonNilRuneSlice is like RuneSlice but returns empty slice instead of nil for nil input.
func NonNilRuneSlice(p []*rune) []rune { return NonNilSliceValue(p, 0) }

// NonNilDurationSlice is like DurationSlice but returns empty slice instead of nil for nil input.
func NonNilDurationSlice(p []*time.Duration) []time.Duration {
	return NonNilSliceValue(p, zeroDuration())
}

// NonNilTimeSlice is like TimeSlice but returns empty slice instead of nil for nil input.
func NonNilTimeSlice(p []*time.Time) []time.Time { return NonNilSliceValue(p, zeroTime()) }
