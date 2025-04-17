package new

import (
	"encoding/json"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

// getHandlerName constructs the handler name based on the handler and method details.
func getHandlerName(handler spec.Handler, method *spec.Method, includeBaseName ...bool) string {
	var addBaseName bool
	baseName, err := getHandlerBaseName(handler)
	if err != nil {
		panic(err)
	}

	if len(includeBaseName) == 0 {
		addBaseName = true
	}

	if method != nil {
		caser := cases.Title(language.English)
		httpMethod := caser.String(strings.ToLower(method.Method))

		// Special case for handler names like "settings", "notification", etc.
		// which should become "PutSettingsHandler" not "PutsettingsHandler"
		if len(baseName) > 0 {
			// Properly capitalize the base name
			baseName = util.ToPascal(baseName)
		}

		// Check if handler.Name already starts with the HTTP method (lowercase)
		// e.g., "getProfile", "postUser", etc.
		lowerHandlerName := strings.ToLower(handler.Name)
		lowerHttpMethod := strings.ToLower(httpMethod)

		// If handler name already starts with the HTTP method, don't add it again
		// Examples: "getFullHTML", "postDemo" already have the method in the name
		if strings.HasPrefix(lowerHandlerName, lowerHttpMethod) {
			// Extract the part after the method and ensure it's properly capitalized
			handlerBaseName := handler.Name[len(lowerHttpMethod):]

			// If handlerBaseName is empty, return just the method name + "Handler"
			if handlerBaseName == "" {
				return httpMethod + "Handler"
			}

			// Ensure the first letter of the base name is capitalized
			return httpMethod + util.ToPascal(handlerBaseName) + "Handler"
		}

		// Otherwise, proceed with normal route name processing
		routeName := getRouteName(handler, method)

		// Check for common prefixes to avoid duplication like "GetgetProfile"
		if strings.HasPrefix(strings.ToLower(routeName), strings.ToLower(httpMethod)) {
			// Remove the duplicated verb from the route name
			routeName = routeName[len(httpMethod):]
		}

		// Also check for base name duplication with route name
		if addBaseName && len(routeName) > 0 && len(baseName) > 0 {
			baseNameLower := strings.ToLower(baseName)
			routeNameLower := strings.ToLower(routeName)

			// If route name ends with base name, don't add base name
			if strings.HasSuffix(routeNameLower, baseNameLower) {
				addBaseName = false
			}
		}

		if addBaseName {
			return httpMethod + routeName + baseName + "Handler"
		}
		return httpMethod + routeName + "Handler"
	}

	return util.ToPascal(baseName + "Handler")
}

// getRouteName returns the sanitized part of the route for naming.
func getRouteName(handler spec.Handler, method *spec.Method) string {
	isModifier := func(part string) bool {
		return strings.EqualFold(part, "static") ||
			strings.EqualFold(part, "socket") ||
			strings.EqualFold(part, "sse") ||
			strings.EqualFold(part, "video") ||
			strings.EqualFold(part, "audio")
	}

	baseRoute := handler.Methods[0].Route // Assuming the first method's route is the base route
	if isModifier(method.Route) {
		j, _ := json.MarshalIndent(method, "", "  ")
		fmt.Println("Modifier", method.Route, string(j))
		panic("")
	}

	trimmedRoute := strings.TrimPrefix(method.Route, baseRoute)
	routeName := titleCaseRoute(trimmedRoute)

	// Clean up the route name to avoid verb duplication
	// Remove common HTTP verbs from the beginning of the route name
	for _, verb := range []string{"Get", "Post", "Put", "Delete", "Patch"} {
		if strings.HasPrefix(routeName, verb) {
			routeName = routeName[len(verb):]
			break
		}
	}

	return routeName
}

func getHandlerBaseName(route spec.Handler) (string, error) {
	name := route.Name
	name = strings.TrimSpace(name)
	name = strings.TrimSuffix(name, "handler")
	name = strings.TrimSuffix(name, "Handler")

	return name, nil
}

func getLogicName(handler spec.Handler) string {
	baseName, err := getHandlerBaseName(handler)
	if err != nil {
		panic(err)
	}

	return baseName + "Logic"
}

// titleCaseRoute converts the route to a title case format suitable for naming.
func titleCaseRoute(route string) string {
	// Remove leading and trailing slashes
	route = strings.Trim(route, "/")

	// Split the route by '/' and process each part
	parts := strings.Split(route, "/")

	for i, part := range parts {
		if part != "" {
			// Handle route parameters
			if strings.HasPrefix(part, ":") {
				parts[i] = "By" + util.ToPascal(strings.TrimPrefix(part, ":"))
			} else {
				// Use ToPascal to properly capitalize each part
				parts[i] = util.ToPascal(part)
			}
		}
	}

	return strings.Join(parts, "")
}

func readFilesInDirectory(dirPath string) ([]string, error) {
	var contents []string

	// Open the directory
	dir, err := os.Open(dirPath)
	if err != nil {
		return nil, err
	}
	defer dir.Close()

	// Read the directory's contents
	files, err := dir.Readdir(-1)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		// Check if it's a file (not a directory)
		if !file.IsDir() {
			filePath := dirPath + "/" + file.Name()

			// Read the file's content
			content, err := os.ReadFile(filePath)
			if err != nil {
				return nil, err
			}

			contents = append(contents, string(content))
		}
	}

	return contents, nil
}

func getLogicFolderPath(server spec.Server, handler spec.Handler) string {
	// fmt.Println("strings.ToLower(util.ToCamel(handler.Name))", strings.ToLower(util.ToCamel(handler.Name)))

	// return path.Join(getLogicLayoutPath(server), strings.ToLower(util.ToCamel(handler.Name)))
	return path.Join(getLogicLayoutPath(server))
}

func getLogicLayoutPath(server spec.Server) string {
	folder := server.GetAnnotation(types.GroupProperty)
	if len(folder) == 0 || folder == "/" {
		return types.LogicDir
	}
	folder = strings.TrimPrefix(folder, "/")
	folder = strings.TrimSuffix(folder, "/")
	// get the last part of the folder
	parts := strings.Split(folder, "/")
	// format the last part of the folder
	parts[len(parts)-1] = strings.ToLower(util.ToCamel(parts[len(parts)-1]))
	folder = filepath.Join(parts...)

	return path.Join(types.LogicDir, folder)
}

func notIn(subject string, list ...string) bool {
	for _, item := range list {
		if item == subject {
			return false
		}
	}

	return true
}

// Converts a path into a name
func pathToName(method, path string) string {
	// Split the path into segments
	segments := strings.Split(strings.Trim(path, "/"), "/")
	var nameParts []string

	for i := 0; i < len(segments); i++ {
		segment := segments[i]
		if strings.HasPrefix(segment, ":") {
			// Handle case where the path starts with a parameter (e.g., /:id)
			if len(nameParts) == 0 {
				nameParts = append(nameParts, "By"+util.ToPascal(segment[1:]))
			} else {
				// Parameter belongs to the preceding segment
				nameParts[len(nameParts)-1] += "By" + util.ToPascal(segment[1:])
			}
		} else {
			// Convert regular segments to PascalCase
			nameParts = append(nameParts, util.ToPascal(segment))
		}
	}

	// Combine method with processed segments
	return strings.ToLower(method) + strings.Join(nameParts, "")
}
