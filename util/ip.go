package util

import (
	"net"
	"net/http"
	"strings"
)

func GetRealIP(r *http.Request) string {
	// Check if the request contains the X-Forwarded-For header
	xForwardedFor := r.Header.Get("X-Forwarded-For")
	if xForwardedFor != "" {
		// X-Forwarded-For header can contain multiple IP addresses separated by commas
		// Usually, the first IP in the list is the original client IP
		ips := strings.Split(xForwardedFor, ",")
		if len(ips) > 0 {
			return strings.TrimSpace(ips[0])
		}
	}

	// Check if the request contains the X-Real-IP header
	xRealIP := r.Header.Get("X-Real-IP")
	if xRealIP != "" {
		return xRealIP
	}

	// Fallback to the address provided by Go's RemoteAddr
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr // If there's an error, return the entire RemoteAddr
	}

	return ip
}
