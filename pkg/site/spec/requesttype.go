package spec

import (
	"strings"

	"github.com/templwind/soul/tools/soul/pkg/site/ast"
)

type RequestType int

const (
	FullHTMLPage RequestType = iota
	PartialHTML
	JSONOutput
	NoOutput
	FormSubmission // Includes both regular form data and file uploads
	WebSocket
	SSEStream
	VideoStream
	AudioStream
)

func DetermineRequestType(method *ast.MethodNode) RequestType {
	if method.IsSocket {
		return WebSocket
	}

	if method.IsSSE || strings.Contains(strings.ToLower(method.Route), "sse") {
		return SSEStream
	}

	if strings.Contains(strings.ToLower(method.Route), "video") ||
		(method.ResponseType != nil && strings.Contains(strings.ToLower(method.ResponseType.(Type).GetName()), "video")) {
		return VideoStream
	}

	if strings.Contains(strings.ToLower(method.Route), "audio") ||
		(method.ResponseType != nil && strings.Contains(strings.ToLower(method.ResponseType.(Type).GetName()), "audio")) {
		return AudioStream
	}

	if method.ReturnsPartial {
		return PartialHTML
	}

	if method.RequestType != nil {
		if hasFormField(method.RequestType) || hasFileUpload(method.RequestType) {
			return FormSubmission
		}
	}

	if method.ResponseType != nil && len(method.ResponseType.(Type).GetName()) > 0 {
		return JSONOutput
	}

	if method.Method == "GET" && (method.RequestType == nil || len(method.RequestType.(Type).GetName()) == 0) {
		return FullHTMLPage
	}

	return NoOutput
}

// Check if the request type has form fields
func hasFormField(reqType interface{}) bool {
	fields := reqType.(Type).GetFields()
	for _, field := range fields {
		if strings.Contains(field.Tag, "form:") {
			return true
		}
	}
	return false
}

// Check if the request type has file upload fields
func hasFileUpload(reqType interface{}) bool {
	fields := reqType.(Type).GetFields()
	for _, field := range fields {
		if strings.Contains(field.Tag, "file:") {
			return true
		}
	}
	return false
}
