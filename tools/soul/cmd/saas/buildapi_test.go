package saas

import (
	"testing"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
)

func TestGetNestedNamespaces(t *testing.T) {
	tests := []struct {
		name              string
		annotations       map[string]string
		routePrefix       string
		expectedPrimary   string
		expectedSecondary string
	}{
		{
			name: "With namespace and subnamespace annotations",
			annotations: map[string]string{
				"namespace":    "blog",
				"subnamespace": "posts",
			},
			routePrefix:       "/api/blog",
			expectedPrimary:   "Blog",
			expectedSecondary: "Posts",
		},
		{
			name: "With namespace annotation only",
			annotations: map[string]string{
				"namespace": "blog",
			},
			routePrefix:       "/api/blog",
			expectedPrimary:   "Blog",
			expectedSecondary: "",
		},
		{
			name: "With group property - single segment",
			annotations: map[string]string{
				types.GroupProperty: "shares",
			},
			routePrefix:       "/api/shares",
			expectedPrimary:   "Shares",
			expectedSecondary: "",
		},
		{
			name: "With group property - multiple segments",
			annotations: map[string]string{
				types.GroupProperty: "api/shares",
			},
			routePrefix:       "/api/shares",
			expectedPrimary:   "Api",
			expectedSecondary: "Shares",
		},
		{
			name:              "With route prefix - single segment",
			annotations:       map[string]string{},
			routePrefix:       "/auth",
			expectedPrimary:   "Auth",
			expectedSecondary: "",
		},
		{
			name:              "With route prefix - multiple segments",
			annotations:       map[string]string{},
			routePrefix:       "/api/auth",
			expectedPrimary:   "Api",
			expectedSecondary: "Auth",
		},
		{
			name:              "With no identifiers",
			annotations:       map[string]string{},
			routePrefix:       "",
			expectedPrimary:   "Api",
			expectedSecondary: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create a server with the test annotations
			server := spec.Server{
				Annotation: spec.Annotation{
					Properties: make(map[string]interface{}),
				},
			}

			// Convert string annotations to interface{} for the Properties map
			for k, v := range tt.annotations {
				server.Annotation.Properties[k] = v
			}

			primaryNS, secondaryNS := getNestedNamespaces(server, tt.routePrefix)

			if primaryNS != tt.expectedPrimary {
				t.Errorf("getNestedNamespaces() primary = %v, want %v", primaryNS, tt.expectedPrimary)
			}

			if secondaryNS != tt.expectedSecondary {
				t.Errorf("getNestedNamespaces() secondary = %v, want %v", secondaryNS, tt.expectedSecondary)
			}
		})
	}
}
