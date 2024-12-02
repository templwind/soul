package saas

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
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
		routeName := getRouteName(handler, method)
		if addBaseName {
			return baseName + strings.Title(strings.ToLower(method.Method)) + routeName + "Handler"
		}
		return strings.Title(strings.ToLower(method.Method)) + routeName + "Handler"
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

	// fmt.Println("RouteName", method.Route, baseRoute, trimmedRoute, routeName)

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
				parts[i] = "By" + strings.Title(strings.TrimPrefix(part, ":"))
			} else {
				parts[i] = strings.Title(part)
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
			content, err := ioutil.ReadFile(filePath)
			if err != nil {
				return nil, err
			}

			contents = append(contents, string(content))
		}
	}

	return contents, nil
}

func getLogicFolderPath(server spec.Server, handler spec.Handler) string {
	return path.Join(getLogicLayoutPath(server), strings.ToLower(util.ToCamel(handler.Name)))
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
