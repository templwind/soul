package saas

import (
	_ "embed"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
)

// buildApi processes and generates TypeScript interfaces from Go structs
func buildApi(builder *SaaSBuilder) error {
	// remove the index.ts file if it exists
	filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "index.ts")
	os.Remove(filename)

	// write the index.ts file
	builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.SrcDir, "lib", "api"),
		templateFile: "templates/app/src/lib/api/index.ts.tpl",
		data:         builder.Data,
	})

	allowedTypes := make(map[string]bool)
	constants := make(map[string]string)

	// Create a tree structure that mirrors the API path hierarchy
	// This structure will group endpoints by their full path
	type NamespaceNode struct {
		Children map[string]*NamespaceNode // Child namespaces
		Content  *strings.Builder          // Endpoint functions at this level
	}

	// Root namespaces (Private, Api, Auth, etc.)
	rootNamespaces := make(map[string]*NamespaceNode)

	// Helper function to get or create a namespace path
	getOrCreateNamespacePath := func(root *NamespaceNode, path []string) *NamespaceNode {
		current := root
		for _, segment := range path {
			if segment == "" {
				continue
			}
			if current.Children == nil {
				current.Children = make(map[string]*NamespaceNode)
			}
			if _, exists := current.Children[segment]; !exists {
				current.Children[segment] = &NamespaceNode{
					Content: new(strings.Builder),
				}
			}
			current = current.Children[segment]
		}
		return current
	}

	// Iterate through all services and methods to identify JSON-returning request and response types
	for _, s := range builder.Spec.Servers {
		routePrefix := strings.ToLower(s.GetAnnotation(types.PrefixProperty))

		// Determine primary namespace from the route prefix or annotations
		primaryNS := getPrimaryNamespace(s, routePrefix)

		// Ensure the root namespace exists
		if _, exists := rootNamespaces[primaryNS]; !exists {
			rootNamespaces[primaryNS] = &NamespaceNode{
				Children: make(map[string]*NamespaceNode),
				Content:  new(strings.Builder),
			}
		}

		for _, srv := range s.Services {
			for _, h := range srv.Handlers {
			outerLoop:
				for _, m := range h.Methods {
					// Handle socket events and constants
					if m.IsSocket {
						for _, node := range m.SocketNode.Topics {
							if node.Topic != "" {
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.Topic))] = node.Topic
							}
							if node.ResponseTopic != "" {
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.ResponseTopic))] = node.ResponseTopic
							}
						}
					}

					if m.IsSocket && m.SocketNode != nil {
						for _, node := range m.SocketNode.Topics {
							if node.RequestType != nil {
								allowedTypes[node.RequestType.GetName()] = true
							}
							if node.ResponseType != nil {
								allowedTypes[node.ResponseType.GetName()] = true
							}
						}
					}

					if m.ReturnsJson {
						var requestType spec.Type
						var responseType spec.Type

						if m.RequestType != nil {
							requestType = findTypeByName(builder.Spec.Types, m.RequestType.GetName())
							if requestType == nil {
								fmt.Println("RequestType not found:", m.RequestType.GetName())
								continue outerLoop
							}

							for _, field := range requestType.GetFields() {
								if strings.Contains(field.Tag, "form:") && !strings.Contains(field.Tag, "json:") {
									continue outerLoop
								}
							}

							allowedTypes[m.RequestType.GetName()] = true
						}

						if m.ResponseType != nil {
							allowedTypes[m.ResponseType.GetName()] = true
							responseType = findTypeByName(builder.Spec.Types, m.ResponseType.GetName())
						} else {
							fmt.Println("ResponseType not found:", m.ResponseType.GetName())
							continue outerLoop
						}

						// Build the path for this endpoint
						// Combine routePrefix and route, removing leading/trailing slashes
						fullPath := path.Join("/", strings.TrimLeft(routePrefix, "/"), m.Route)
						fullPath = strings.TrimPrefix(fullPath, "/")

						// Generate path segments for namespacing
						pathSegments := generatePathSegments(fullPath)

						// Always use the path-based namespace structure
						targetNode := getOrCreateNamespacePath(rootNamespaces[primaryNS], pathSegments)

						// Write the endpoint to the target namespace
						writeApiEndpoint(builder, targetNode.Content, requestType, responseType, h, m, routePrefix)
					}
				}
			}
		}
	}

	// Assemble all namespaces into the final endpoints string
	endpointBuilder := new(strings.Builder)

	// Sort root namespace names for consistent output
	rootNames := make([]string, 0, len(rootNamespaces))
	for name := range rootNamespaces {
		rootNames = append(rootNames, name)
	}
	sort.Strings(rootNames)

	// Helper function to recursively write namespaces
	var writeNamespace func(node *NamespaceNode, name string, indent string)

	writeNamespace = func(node *NamespaceNode, name string, indent string) {
		// Skip namespaces with no content and no children
		if (node.Content == nil || node.Content.Len() == 0) && (node.Children == nil || len(node.Children) == 0) {
			return
		}

		// Write namespace declaration
		fmt.Fprintf(endpointBuilder, "%sexport namespace %s {\n", indent, name)

		// Write content at this level
		if node.Content != nil && node.Content.Len() > 0 {
			lines := strings.Split(node.Content.String(), "\n")
			for _, line := range lines {
				if line != "" {
					fmt.Fprintf(endpointBuilder, "%s  %s\n", indent, line)
				}
			}

			// Add a line break if there are both content and children
			if len(node.Children) > 0 {
				fmt.Fprint(endpointBuilder, "\n")
			}
		}

		// Write child namespaces
		if len(node.Children) > 0 {
			// Sort child names for consistent output
			childNames := make([]string, 0, len(node.Children))
			for childName := range node.Children {
				childNames = append(childNames, childName)
			}
			sort.Strings(childNames)

			// Process each child
			for _, childName := range childNames {
				writeNamespace(node.Children[childName], util.ToPascal(childName), indent+"  ")
			}
		}

		// Close namespace
		fmt.Fprintf(endpointBuilder, "%s}\n\n", indent)
	}

	// Write all root namespaces
	for _, name := range rootNames {
		writeNamespace(rootNamespaces[name], name, "")
	}

	builder.Data["Endpoints"] = strings.TrimSpace(endpointBuilder.String())

	if !builder.IsService {
		filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "endpoints.ts")
		os.Remove(filename)
		// Generate the endpoints.ts file
		if err := builder.genFile(fileGenConfig{
			subdir:       path.Join(builder.ServiceName, types.SrcDir, "lib", "api"),
			templateFile: "templates/app/src/lib/api/endpoints.ts.tpl",
			data:         builder.Data,
		}); err != nil {
			fmt.Println(util.WrapErr(err, "endpoints.ts generate error"))
		}
	}

	writeConstants(builder, constants)

	// Recursively add all necessary types
	for name := range allowedTypes {
		tp := findTypeByName(builder.Spec.Types, name)
		if tp != nil {
			addAllRequiredTypes(tp, allowedTypes, builder.Spec.Types, false)
		}
	}

	if !builder.IsService {
		// Generate TypeScript models for identified types
		err := genApiTypes(builder, allowedTypes)
		if err != nil {
			return err
		}
	}

	return nil
}

// getPrimaryNamespace determines the primary namespace for a server
func getPrimaryNamespace(server spec.Server, routePrefix string) string {
	// First try to get explicit namespace annotation
	primaryNS := server.GetAnnotation("namespace")
	if primaryNS != "" {
		return util.ToPascal(primaryNS)
	}

	// Next, try to use the group property
	group := server.GetAnnotation(types.GroupProperty)
	if group != "" {
		// Clean up the group name for use as a namespace
		group = strings.TrimPrefix(group, "/")
		group = strings.TrimSuffix(group, "/")

		// Get the first segment
		segments := strings.Split(group, "/")
		if len(segments) > 0 {
			return util.ToPascal(segments[0])
		}
	}

	// Finally, fall back to route prefix if available
	if routePrefix != "" {
		routePrefix = strings.TrimPrefix(routePrefix, "/")
		routePrefix = strings.TrimSuffix(routePrefix, "/")

		if routePrefix != "" {
			// Get the first segment
			segments := strings.Split(routePrefix, "/")
			if len(segments) > 0 {
				return util.ToPascal(segments[0])
			}
		}
	}

	// Default namespace if nothing else is available
	return "Api"
}

// generatePathSegments creates a list of path segments for namespacing
func generatePathSegments(routePath string) []string {
	// Split the route into segments
	segments := strings.Split(routePath, "/")

	// Clean up the segments and filter out empty ones
	var cleanSegments []string
	for i, segment := range segments {
		// Skip the first segment (handled by primary namespace)
		if i == 0 {
			continue
		}

		// Keep all non-empty segments
		if segment != "" {
			cleanSegments = append(cleanSegments, segment)
		}
	}

	return cleanSegments
}

// findTypeByName finds a type by name from a list of types
func findTypeByName(allTypes []spec.Type, name string) spec.Type {
	for _, tp := range allTypes {
		// strip [] and *
		cleanName := strings.ReplaceAll(name, "[]", "")
		cleanName = strings.ReplaceAll(cleanName, "*", "")

		if strings.EqualFold(tp.GetName(), cleanName) {
			return tp
		}
	}
	return nil
}

// addAllRequiredTypes recursively adds all required types to the allowedTypes map
func addAllRequiredTypes(tp spec.Type, allowedTypes map[string]bool, allTypes []spec.Type, addAllFound bool) {
	self := tp.GetName()
	allowedTypes[tp.GetName()] = true // Mark the current type as allowed

	// Iterate through all fields to find non-primitive types and process them recursively
	// let's make sure we don't get caught in an infinite loop
	visited := make(map[string]bool)

	for _, field := range tp.GetFields() {
		fieldType := cleanTypeName(field.Type)

		if fieldType == self {
			continue
		}

		// if we've already visited this type, skip it
		if visited[fieldType] {
			continue
		}
		visited[fieldType] = true

		// Skip primitive types
		if isPrimitive(fieldType) {
			continue
		}

		if addAllFound {
			allowedTypes[fieldType] = true
		}

		// Find the corresponding type for the field and add it recursively if it's not already allowed
		requiredTp := findTypeByName(allTypes, fieldType)
		if requiredTp != nil {
			addAllRequiredTypes(requiredTp, allowedTypes, allTypes, true)
		}
	}
}

// cleanTypeName removes pointer and array brackets from the type name
func cleanTypeName(typeName string) string {
	out := strings.ReplaceAll(typeName, "[]", "")
	out = strings.ReplaceAll(out, "*", "")
	re := regexp.MustCompile(`map\[.*\](.*)`)
	out = re.ReplaceAllString(out, "$1")
	return out
}

// isPrimitive checks if a type is a primitive Go type
func isPrimitive(tp string) bool {
	switch tp {
	case "int", "int8", "int16", "int32", "int64",
		"uint", "uint8", "uint16", "uint32", "uint64",
		"float32", "float64",
		"map[string]string",
		"map[string]int",
		"map[string]float64",
		"map[string]bool",
		"map[string]interface{}",
		"any",
		"string",
		"[]string",
		"bool",
		"[]byte",
		"time.Time",
		"time.Duration":
		return true
	default:
		return false
	}
}

// sortAllowedTypesKeys returns a sorted slice of keys from the allowedTypes map
func sortAllowedTypesKeys(allowedTypes map[string]bool) []string {
	// Create a slice to hold the keys
	keys := make([]string, 0, len(allowedTypes))

	// Append all keys from the map to the slice
	for key := range allowedTypes {
		keys = append(keys, key)
	}

	// Sort the slice of keys
	sort.Strings(keys)

	return keys
}

// genApiTypes generates TypeScript interfaces for allowed types
func genApiTypes(builder *SaaSBuilder, allowedTypes map[string]bool) error {
	var modelBuilder strings.Builder
	first := true

	// Sort the keys of the allowedTypes map alphabetically
	sortedKeys := sortAllowedTypesKeys(allowedTypes)

	// Create a map from allowedTypes for fast lookup
	allowedMap := make(map[string]spec.Type)
	for _, tp := range builder.Spec.Types {
		if allowedTypes[tp.GetName()] {
			allowedMap[tp.GetName()] = tp
		}
	}

	// Iterate through sorted keys and write the types
	for _, key := range sortedKeys {
		tp := allowedMap[key] // Get the corresponding type from the map
		if tp != nil {
			if !first {
				modelBuilder.WriteString("\n\n")
			}
			first = false
			if err := writeApiType(builder, &modelBuilder, tp); err != nil {
				return util.WrapErr(err, tp.GetName()+" generate error")
			}
		}
	}

	filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "models.ts")
	os.Remove(filename)

	models := modelBuilder.String()

	builder.Data["Models"] = models

	// Generate the models.ts file
	if err := builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.SrcDir, "lib", "api"),
		templateFile: "templates/app/src/lib/api/models.ts.tpl",
		data:         builder.Data,
	}); err != nil {
		fmt.Println(util.WrapErr(err, "models.ts generate error"))
	}

	return nil
}

func writeConstants(builder *SaaSBuilder, constants map[string]string) error {
	// sort constants in reverse
	keys := make([]string, 0, len(constants))
	for key := range constants {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	constantsBuilder := new(strings.Builder)
	hasBreak := false
	fmt.Fprintf(constantsBuilder, "// WS Requests\n")
	for _, key := range keys {
		if strings.HasPrefix(key, "WS_RESPONSE_") && !hasBreak {
			fmt.Fprintf(constantsBuilder, "\n// WS Responses\n")
			hasBreak = true
		}
		fmt.Fprintf(constantsBuilder, "export const %s = '%s';\n", key, constants[key])
	}

	builder.Data["Constants"] = constantsBuilder.String()

	filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "constants.ts")
	os.Remove(filename)

	// Generate the models.ts file
	if err := builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.SrcDir, "lib", "api"),
		templateFile: "templates/app/src/lib/api/constants.ts.tpl",
		data:         builder.Data,
	}); err != nil {
		fmt.Println(util.WrapErr(err, "constants.ts generate error"))
	}

	return nil
}

// getRouteBasedNamespace determines the namespace name based on the route
func getRouteBasedNamespace(route string) string {
	routePath := strings.TrimPrefix(route, "/")

	// Transform the route path into a namespace
	if routePath == "" || routePath == "/" {
		return "Index"
	} else if strings.HasPrefix(routePath, ":") {
		// For routes like /:slug, use the parameter name as namespace
		paramName := strings.TrimPrefix(routePath, ":")
		return util.ToPascal(paramName)
	} else {
		// Split the path into segments and remove empty ones
		segments := []string{}
		for _, s := range strings.Split(routePath, "/") {
			if s != "" && !strings.HasPrefix(s, ":") {
				segments = append(segments, s)
			}
		}

		// No segments left after filtering
		if len(segments) == 0 {
			return "Index"
		}

		// Generate namespace based on path structure and depth
		if len(segments) >= 3 {
			// For deeper paths, use a more specific namespace derived from multiple segments
			// For paths like /api/oauth/zapier/client-id, create namespaces like ZapierClientId
			lastSegmentIndex := len(segments) - 1
			secondLastSegmentIndex := len(segments) - 2

			// Form a composite namespace from the last two non-parameter segments
			lastSegment := util.ToPascal(segments[lastSegmentIndex])
			secondLastSegment := util.ToPascal(segments[secondLastSegmentIndex])

			// If both segments are valid, combine them for a unique namespace
			if lastSegment != "" && secondLastSegment != "" {
				return secondLastSegment + lastSegment
			}
		}

		// Default to using the last non-empty segment
		for i := len(segments) - 1; i >= 0; i-- {
			if segments[i] != "" {
				return util.ToPascal(segments[i])
			}
		}
	}

	// If we couldn't determine a route-based namespace, use a default
	return "Endpoint"
}

func writeApiEndpoint(builder *SaaSBuilder, endpointBuilder io.Writer, requestType, responseType spec.Type, h spec.Handler, m spec.Method, routePrefix string) error {
	var reqParams []string
	var request, response string
	var totalFields int
	var queryParams []string
	pathParams := make(map[string]string)

	hasRequestObject := false
	if requestType != nil {
		totalFields = len(requestType.GetFields())
		allFieldsArePath := true

		// Check all fields first to determine if they're all path parameters
		for _, field := range requestType.GetFields() {
			if !strings.Contains(field.Tag, "path:") {
				allFieldsArePath = false
				break
			}
		}

		// Only add request object if there are non-path fields
		// For GET, PUT, DELETE methods with only path parameters, don't add a request object
		if !strings.Contains(m.Route, ":") && totalFields > 0 &&
			!((strings.ToUpper(m.Method) == "GET" ||
				strings.ToUpper(m.Method) == "PUT" ||
				strings.ToUpper(m.Method) == "DELETE") && allFieldsArePath) {
			request = fmt.Sprintf("req: models.%s", requestType.GetName())
			hasRequestObject = true
		}

		// Handle parameters
		for _, field := range requestType.GetFields() {
			fieldName := util.FirstToLower(field.Name)
			if len(field.Name) <= 3 {
				fieldName = strings.ToLower(field.Name)
			}

			if strings.Contains(field.Tag, "path:") {
				// Handle path parameters
				totalFields--
				reqParams = append(reqParams, fmt.Sprintf("%s: %s", fieldName, ConvertToTypeScriptType(builder, field.Type)))

				// Extract the path parameter name from the tag
				re := regexp.MustCompile(`path:"([^"]+)"`)
				if matches := re.FindStringSubmatch(field.Tag); len(matches) > 1 {
					pathParams[matches[1]] = fieldName
				} else {
					pathParams[strings.ToLower(field.Name)] = fieldName
				}
			} else if strings.Contains(field.Tag, "query:") || strings.ToUpper(m.Method) == "GET" {
				// Handle query parameters
				totalFields--
				reqParams = append(reqParams, fmt.Sprintf("%s: %s", fieldName, ConvertToTypeScriptType(builder, field.Type)))
				queryParams = append(queryParams, fmt.Sprintf("%s=${%s}", fieldName, fieldName))
			}
		}
	}

	// Add any primitive parameters that appear before 'options' as path parameters
	primitiveParams := []string{}
	if len(reqParams) > 0 {
		for _, param := range reqParams {
			if !strings.Contains(param, "req:") && !strings.Contains(param, "options?:") {
				parts := strings.Split(param, ":")
				if len(parts) == 2 {
					paramName := strings.TrimSpace(parts[0])
					primitiveParams = append(primitiveParams, paramName)
				}
			}
		}
	}

	// We'll update route parameters after detecting any in the URL path
	route := path.Join("/", strings.TrimLeft(routePrefix, "/"), m.Route)

	// First, extract all :param patterns from the route
	routeParamRegex := regexp.MustCompile(`:(\w+)`)
	routeParams := routeParamRegex.FindAllStringSubmatch(route, -1)

	// Add route parameters to pathParams if they're not already there
	for _, param := range routeParams {
		if param[1] != "" && pathParams[param[1]] == "" {
			// Convert the parameter name to camelCase if needed
			paramName := util.FirstToLower(param[1])
			pathParams[param[1]] = paramName

			// Add missing path parameters to reqParams if they weren't defined in the request type
			// This ensures they show up in the function signature
			paramFound := false
			for _, existingParam := range reqParams {
				if strings.HasPrefix(existingParam, paramName+":") {
					paramFound = true
					break
				}
			}

			if !paramFound {
				reqParams = append(reqParams, fmt.Sprintf("%s: string", paramName))
				primitiveParams = append(primitiveParams, paramName)
			}
		}
	}

	// Replace path parameters in the route
	for param, varName := range pathParams {
		route = strings.ReplaceAll(route, ":"+param, "${"+varName+"}")
	}

	// Format parameters after all path parameters have been processed
	params := strings.Join(reqParams, ", ")
	if request != "" {
		if params != "" {
			params += ", "
		}
		params += request
	}
	if params != "" {
		params += ", "
	}
	params += "options?: { fetch?: typeof fetch }"

	if responseType != nil {
		response = fmt.Sprintf(": Promise<models.%s>", util.ToTitle(m.ResponseType.GetName()))
	}

	// Generate a simple function name based on the HTTP method
	functionName := util.ToPascal(strings.ToLower(m.Method))

	// If we have path parameters, append them to the function name
	// Example: GET /api/posts/:slug -> GetBySlug
	if len(routeParams) > 0 {
		pathParamParts := []string{}
		for _, param := range routeParams {
			if param[1] != "" {
				pathParamParts = append(pathParamParts, util.ToPascal(param[1]))
			}
		}

		// Sort param names for consistency when multiple parameters exist
		sort.Strings(pathParamParts)

		// Add "By" prefix and join all parameter names
		if len(pathParamParts) > 0 {
			functionName += "By" + strings.Join(pathParamParts, "And")
		}
	}

	// Write the function definition
	fmt.Fprintf(endpointBuilder, "export function %s(%s)%s {\n", functionName, params, response)

	// Determine the proper indentation (1 tab/2 spaces)
	indentation := "  "

	// Write the API call
	fmt.Fprintf(endpointBuilder, "%sreturn api.%s<models.%s>(`%s`, ", indentation, strings.ToLower(m.Method), util.ToTitle(m.ResponseType.GetName()), route)

	// Add request parameter if needed
	if strings.ToLower(m.Method) == "get" {
		fmt.Fprintf(endpointBuilder, "undefined, options?.fetch)")
	} else if hasRequestObject {
		fmt.Fprintf(endpointBuilder, "req, undefined, options?.fetch)")
	} else {
		fmt.Fprintf(endpointBuilder, "undefined, undefined, options?.fetch)")
	}

	// Close the function
	fmt.Fprintf(endpointBuilder, "\n")
	fmt.Fprintf(endpointBuilder, "}\n")

	return nil
}

func findFieldType(builder *SaaSBuilder, name string) *string {
	// search the types folder for files containing the type name
	files, err := filepath.Glob(path.Join(builder.ServiceName, types.TypesDir, "*.go"))
	if err != nil {
		return nil
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return nil
		}
		// look at the file line by line
		lines := strings.Split(string(content), "\n")
		for _, line := range lines {
			line = strings.TrimSpace(line)
			// ignore comments
			if strings.HasPrefix(line, "//") {
				continue
			}
			re := regexp.MustCompile(`^type\s+` + regexp.QuoteMeta(name) + `\s+`)
			if re.MatchString(line) {
				// determine the type of the field
				typeRe := regexp.MustCompile(`type\s+(\w+)\s+(\w+)`)
				out := typeRe.FindAllStringSubmatch(string(content), -1)
				if len(out) > 0 && len(out[0]) > 2 {
					if out[0][2] == "string" {
						return &out[0][2]
					}
				}
			}
		}
	}
	return nil
}

// writeApiType writes the TypeScript interface definition for a given type
func writeApiType(builder *SaaSBuilder, modelBuilder io.Writer, tp spec.Type) error {
	if tp != nil {
		fmt.Fprintf(modelBuilder, "export interface %s {\n", util.ToTitle(tp.GetName()))

		for _, member := range tp.GetFields() {
			isOptional := strings.Contains(member.Tag, "omitempty")
			fieldName := extractFieldName(member.Tag, member.Name)
			if err := WriteApiProperty(builder, modelBuilder, fieldName, member.Type, isOptional, 1); err != nil {
				return err
			}
		}
		fmt.Fprintf(modelBuilder, "}")
	}
	return nil
}

// extractFieldName extracts the JSON field name from the struct tag, falling back to the default name
func extractFieldName(tag, defaultName string) string {
	re := regexp.MustCompile(`(?:json|form):"([\w]+)`)
	out := re.FindAllStringSubmatch(tag, -1)
	if len(out) > 0 && len(out[0]) > 1 {
		return out[0][1]
	}
	return defaultName
}

// WriteApiProperty writes a TypeScript property definition
func WriteApiProperty(builder *SaaSBuilder, writer io.Writer, name, tp string, isOptional bool, indent int) error {
	// Use a utility function to write indentation
	util.WriteIndent(writer, indent)

	// Remove pointer symbols
	tp = strings.ReplaceAll(tp, "*", "")

	// Convert Go-specific types to TypeScript
	tsType := ConvertToTypeScriptType(builder, tp)

	// Determine if the property is optional
	optionalMark := ""
	if isOptional {
		optionalMark = "?"
	}

	// Write the property in TypeScript format with camelCase property name
	_, err := fmt.Fprintf(writer, "%s%s: %s;\n", util.FirstToLower(name), optionalMark, tsType)

	return err
}

// ConvertToTypeScriptType converts Go types to TypeScript types
func ConvertToTypeScriptType(builder *SaaSBuilder, goType string) string {
	fieldType := findFieldType(builder, goType)
	if fieldType != nil {
		goType = *fieldType
	}

	switch goType {
	case "int", "int8", "int16", "int32", "int64",
		"uint", "uint8", "uint16", "uint32", "uint64",
		"float32", "float64":
		return "number"
	case "bool":
		return "boolean"
	case "string":
		return "string"
	case "[]byte":
		return "Uint8Array"
	case "time.Time":
		return "string"
	case "time.Duration":
		return "number"
	default:
		// Handle slices and maps
		if strings.HasPrefix(goType, "[]") {
			elementType := goType[2:]
			return fmt.Sprintf("%s[]", ConvertToTypeScriptType(builder, elementType))
		}
		if strings.HasPrefix(goType, "map[") && strings.Contains(goType, "]") {
			keyValueTypes := goType[4:]
			parts := strings.SplitN(keyValueTypes, "]", 2)
			if len(parts) == 2 {
				keyType := ConvertToTypeScriptType(builder, parts[0])
				valueType := ConvertToTypeScriptType(builder, parts[1])
				return fmt.Sprintf("Record<%s, %s>", keyType, valueType)
			}
		}
		return goType
	}
}

// getNestedNamespaces determines the primary and secondary namespaces for a server
// This function is maintained for backward compatibility with tests
func getNestedNamespaces(server spec.Server, routePrefix string) (string, string) {
	// Get primary namespace using the new approach
	primaryNS := getPrimaryNamespace(server, routePrefix)

	// Check for explicit subnamespace annotation
	secondaryNS := server.GetAnnotation("subnamespace")
	if secondaryNS != "" {
		return primaryNS, util.ToPascal(secondaryNS)
	}

	// Check group property for secondary namespace
	group := server.GetAnnotation(types.GroupProperty)
	if group != "" {
		group = strings.TrimPrefix(group, "/")
		group = strings.TrimSuffix(group, "/")

		segments := strings.Split(group, "/")
		if len(segments) > 1 {
			return primaryNS, util.ToPascal(segments[1])
		} else {
			// For "group" property with single segment, the test expects empty secondary
			return primaryNS, ""
		}
	}

	// Check route prefix for secondary namespace
	if routePrefix != "" {
		routePrefix = strings.TrimPrefix(routePrefix, "/")
		routePrefix = strings.TrimSuffix(routePrefix, "/")

		segments := strings.Split(routePrefix, "/")
		if len(segments) > 1 {
			return primaryNS, util.ToPascal(segments[1])
		} else {
			// For single-segment route prefix, the test expects empty secondary
			return primaryNS, ""
		}
	}

	return primaryNS, ""
}
