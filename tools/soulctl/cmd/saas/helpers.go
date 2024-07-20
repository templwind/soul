package saas

import (
	"io/ioutil"
	"os"
	"strings"

	"github.com/templwind/soul/tools/soulctl/internal/util"
	"github.com/templwind/soul/tools/soulctl/pkg/site/spec"
)

// getHandlerName constructs the handler name based on the handler and method details.
func getHandlerName(handler spec.Handler, method *spec.Method, includeBaseName bool) string {
	baseName, err := getHandlerBaseName(handler)
	if err != nil {
		panic(err)
	}

	if method != nil {
		routeName := getRouteName(handler, method)
		if includeBaseName {
			return baseName + strings.Title(strings.ToLower(method.Method)) + routeName + "Handler"
		}
		return strings.Title(strings.ToLower(method.Method)) + routeName + "Handler"
	}

	return util.ToPascal(baseName + "Handler")
}

// getRouteName returns the sanitized part of the route for naming.
func getRouteName(handler spec.Handler, method *spec.Method) string {
	baseRoute := handler.Methods[0].Route // Assuming the first method's route is the base route
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
