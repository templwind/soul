package new

import (
	"bytes"
	_ "embed"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"text/template"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
	"github.com/zeromicro/go-zero/tools/goctl/util/pathx"
)

// buildApi processes and generates TypeScript interfaces based on ClientConfigs
func buildApi(builder *SaaSBuilder) error {
	if len(builder.ClientConfigs) == 0 {
		// If no specific clients are requested, maybe generate a default one?
		// Or simply return. For now, let's return.
		fmt.Println("No API clients requested via --client flag, skipping generation.")
		return nil
	}

	allowedTypes := make(map[string]bool)
	constants := make(map[string]string)

	// Create maps to store endpoints by namespace for both versions
	defaultEndpoints := make(map[string]*strings.Builder)
	adminEndpoints := make(map[string]*strings.Builder)

	// STEP 1: Collect all types, constants, and endpoints from the spec
	// ------------------------------------------------------------------
	for _, s := range builder.Spec.Servers {
		routePrefix := strings.ToLower(s.GetAnnotation(types.PrefixProperty))
		primaryNS := getPrimaryNamespace(s, routePrefix)
		isAdmin := strings.Contains(strings.ToLower(routePrefix), "admin") ||
			strings.Contains(strings.ToLower(primaryNS), "admin")

		// Ensure the namespace exists in both maps
		if _, exists := defaultEndpoints[primaryNS]; !exists {
			defaultEndpoints[primaryNS] = new(strings.Builder)
		}
		if _, exists := adminEndpoints[primaryNS]; !exists {
			adminEndpoints[primaryNS] = new(strings.Builder)
		}

		for _, srv := range s.Services {
			for _, h := range srv.Handlers {
			outerLoop:
				for _, m := range h.Methods {
					// Collect constants from socket topics
					if m.IsSocket {
						for _, node := range m.SocketNode.Topics {
							if node.Topic != "" {
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.Topic))] = node.Topic
							}
							if node.ResponseTopic != "" {
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.ResponseTopic))] = node.ResponseTopic
							}
							if node.RequestType != nil {
								allowedTypes[node.RequestType.GetName()] = true
							}
							if node.ResponseType != nil {
								allowedTypes[node.ResponseType.GetName()] = true
							}
						}
					}

					// Collect types and endpoints for JSON-returning methods
					if m.ReturnsJson {
						var requestType spec.Type
						var responseType spec.Type

						// Collect request type
						if m.RequestType != nil {
							requestType = findTypeByName(builder.Spec.Types, m.RequestType.GetName())
							if requestType == nil {
								fmt.Println("Warning: RequestType not found:", m.RequestType.GetName())
								// continue outerLoop // Decide if you want to skip or proceed without request type
							} else {
								// Check for form types not allowed in JSON endpoints
								for _, field := range requestType.GetFields() {
									if strings.Contains(field.Tag, "form:") && !strings.Contains(field.Tag, "json:") {
										continue outerLoop
									}
								}
								allowedTypes[m.RequestType.GetName()] = true
							}
						}

						// Collect response type
						if m.ResponseType != nil {
							responseType = findTypeByName(builder.Spec.Types, m.ResponseType.GetName())
							if responseType == nil {
								fmt.Println("Warning: ResponseType not found:", m.ResponseType.GetName())
								// continue outerLoop // Decide if you want to skip or proceed without response type
							} else {
								allowedTypes[m.ResponseType.GetName()] = true
							}
						} else {
							// Handle cases where ReturnsJson is true but ResponseType is nil (e.g., return generic response)
							// You might want to define a default response type or skip
							// fmt.Println("Warning: ReturnsJson is true but ResponseType is nil for handler", h.Name)
						}

						// Write the endpoint to the appropriate maps
						writeApiEndpoint(builder, adminEndpoints[primaryNS], requestType, responseType, h, m, routePrefix)
						if !isAdmin {
							writeApiEndpoint(builder, defaultEndpoints[primaryNS], requestType, responseType, h, m, routePrefix)
						}
					}
				}
			}
		}
	}

	// Recursively add all necessary dependent types
	for name := range allowedTypes {
		tp := findTypeByName(builder.Spec.Types, name)
		if tp != nil {
			addAllRequiredTypes(tp, allowedTypes, builder.Spec.Types, false)
		}
	}

	// STEP 2: Generate content for shared files (Models, Constants, API Client)
	// ------------------------------------------------------------------------
	modelsContent, err := generateModelsContent(builder, allowedTypes)
	if err != nil {
		return fmt.Errorf("failed to generate models content: %w", err)
	}

	constantsContent := generateConstantsContent(constants)

	apiClientContent, err := generateApiClientContent(builder)
	if err != nil {
		return fmt.Errorf("failed to generate api client content: %w", err)
	}

	// STEP 3: Iterate through client configurations and generate files
	// ------------------------------------------------------------------
	for _, clientConfig := range builder.ClientConfigs {
		fmt.Printf("Generating API client type '%s' at: %s\n", clientConfig.Type, clientConfig.Path)

		// Ensure target directory exists
		if err := pathx.MkdirIfNotExist(clientConfig.Path); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", clientConfig.Path, err)
		}

		// Determine which endpoints map to use
		endpointsMap := defaultEndpoints
		if clientConfig.Type == "admin" {
			endpointsMap = adminEndpoints
		}

		// --- Generate and write individual files ---

		// index.ts
		if err := writeContentToFile(
			builder,
			clientConfig.Path,
			"index.ts",
			"templates/src/lib/api/index.ts.tpl",
			builder.Data, // index.ts might not need specific data
		); err != nil {
			fmt.Println(util.WrapErr(err, fmt.Sprintf("index.ts generation error for %s", clientConfig.Path)))
		}

		// models.ts
		if err := writeStringToFile(clientConfig.Path, "models.ts", modelsContent); err != nil {
			fmt.Println(util.WrapErr(err, fmt.Sprintf("models.ts write error for %s", clientConfig.Path)))
		}

		// constants.ts
		if err := writeStringToFile(clientConfig.Path, "constants.ts", constantsContent); err != nil {
			fmt.Println(util.WrapErr(err, fmt.Sprintf("constants.ts write error for %s", clientConfig.Path)))
		}

		// api-client.ts
		if err := writeStringToFile(clientConfig.Path, "api-client.ts", apiClientContent); err != nil {
			fmt.Println(util.WrapErr(err, fmt.Sprintf("api-client.ts write error for %s", clientConfig.Path)))
		}

		// endpoints.ts (specific to client type)
		endpointsContent := generateEndpointsContent(endpointsMap)
		if err := writeStringToFile(clientConfig.Path, "endpoints.ts", endpointsContent); err != nil {
			fmt.Println(util.WrapErr(err, fmt.Sprintf("endpoints.ts write error for %s (%s)", clientConfig.Path, clientConfig.Type)))
		}
	}

	return nil
}

// --- Helper functions for generating content strings ---

func generateModelsContent(builder *SaaSBuilder, allowedTypes map[string]bool) (string, error) {
	var modelBuilder strings.Builder
	first := true

	sortedKeys := sortAllowedTypesKeys(allowedTypes)
	allowedMap := make(map[string]spec.Type)
	for _, tp := range builder.Spec.Types {
		if allowedTypes[tp.GetName()] {
			allowedMap[tp.GetName()] = tp
		}
	}

	// Add header comment
	modelBuilder.WriteString("// Code generated by soul. DO NOT EDIT.\n\n")

	for _, key := range sortedKeys {
		tp := allowedMap[key]
		if tp != nil {
			if !first {
				modelBuilder.WriteString("\n\n")
			}
			first = false
			if err := writeApiType(builder, &modelBuilder, tp); err != nil {
				return "", util.WrapErr(err, tp.GetName()+" type generation error")
			}
		}
	}
	return modelBuilder.String(), nil
}

func generateConstantsContent(constants map[string]string) string {
	keys := make([]string, 0, len(constants))
	for key := range constants {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	var constantsBuilder strings.Builder
	hasBreak := false
	constantsBuilder.WriteString("// Code generated by soul. DO NOT EDIT.\n\n")
	constantsBuilder.WriteString("// WS Requests\n")
	for _, key := range keys {
		if strings.HasPrefix(key, "WS_RESPONSE_") && !hasBreak {
			constantsBuilder.WriteString("\n// WS Responses\n")
			hasBreak = true
		}
		fmt.Fprintf(&constantsBuilder, "export const %s = '%s';\n", key, constants[key])
	}
	return constantsBuilder.String()
}

func generateApiClientContent(builder *SaaSBuilder) (string, error) {
	// API client content is static, just read the template
	templateFile := "templates/src/lib/api/api-client.ts.tpl"
	// Use the FS from the builder instance
	contentBytes, err := builder.TemplatesFS.ReadFile(templateFile)
	if err != nil {
		return "", fmt.Errorf("failed to read api-client template %s: %w", templateFile, err)
	}
	// Prepend the standard comment
	return "// Code generated by soul. DO NOT EDIT.\n\n" + string(contentBytes), nil
}

func generateEndpointsContent(endpoints map[string]*strings.Builder) string {
	var endpointBuilder strings.Builder
	namespaceNames := make([]string, 0, len(endpoints))
	for name := range endpoints {
		namespaceNames = append(namespaceNames, name)
	}
	sort.Strings(namespaceNames)

	endpointBuilder.WriteString("// Code generated by soul. DO NOT EDIT.\n\n")
	// TODO: Fix relative paths based on final structure
	endpointBuilder.WriteString("import client from \"./api-client\";\n")
	endpointBuilder.WriteString("import * as models from \"./models\";\n\n")

	for _, name := range namespaceNames {
		content := endpoints[name].String()
		if content != "" {
			fmt.Fprintf(&endpointBuilder, "// %s endpoints\nexport const %s = {\n%s};\n\n", name, util.FirstToLower(name), content)
		}
	}
	return strings.TrimSpace(endpointBuilder.String())
}

// --- Helper functions for writing content to files ---

// writeStringToFile writes the given string content to a file.
func writeStringToFile(dir, filename, content string) error {
	if content == "" {
		return nil // Don't write empty files
	}
	filePath := filepath.Join(dir, filename)
	return os.WriteFile(filePath, []byte(content), 0644)
}

// writeContentToFile generates content from a template and writes it to a file.
func writeContentToFile(builder *SaaSBuilder, dir, filename, templatePath string, data map[string]any) error {
	// Ensure the template path starts with "templates/"
	if !strings.HasPrefix(templatePath, "templates/") {
		templatePath = "templates/" + templatePath
	}

	tmpl, err := template.New(filepath.Base(templatePath)).
		Funcs(builder.TemplateFuncs).              // Use the correct field name: TemplateFuncs
		ParseFS(builder.TemplatesFS, templatePath) // Use the FS from the builder instance
	if err != nil {
		return fmt.Errorf("parsing template %s: %w", templatePath, err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		return fmt.Errorf("executing template %s: %w", templatePath, err)
	}

	return writeStringToFile(dir, filename, "// Code generated by soul. DO NOT EDIT.\n\n"+buf.String())
}

// --- Existing helper functions (potentially remove redundant ones) ---

// REMOVED: generateEndpointsFile (replaced by generateEndpointsContent and writeStringToFile)
// REMOVED: generateApiClientFile (replaced by generateApiClientContent and writeStringToFile)
// REMOVED: genApiTypes (replaced by generateModelsContent)
// REMOVED: writeConstants (replaced by generateConstantsContent)

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

// writeApiEndpoint remains largely the same, writing to the provided endpointBuilder (io.Writer)
func writeApiEndpoint(builder *SaaSBuilder, endpointBuilder io.Writer, requestType, responseType spec.Type, h spec.Handler, m spec.Method, routePrefix string) error {
	var reqParams []string
	var request, response string
	var totalFields int
	pathParams := make(map[string]string)
	queryParams := make(map[string]string)

	hasRequestObject := false
	hasBodyParams := false
	if requestType != nil {
		totalFields = len(requestType.GetFields())

		// Check if we have any form or json body parameters
		for _, field := range requestType.GetFields() {
			if strings.Contains(field.Tag, "form:") || strings.Contains(field.Tag, "json:") {
				hasBodyParams = true
				break
			}
		}

		// Get the request type kind using RequestGoTypeName
		requestKind := util.RequestGoTypeName(m, types.TypesPacket)

		// Only add request object if there are form/json body fields
		if hasBodyParams {
			if strings.HasPrefix(requestKind, "[]") || strings.HasPrefix(requestKind, "*[]") {
				request = fmt.Sprintf("data: models.%s[]", requestType.GetName())
			} else {
				request = fmt.Sprintf("data: models.%s", requestType.GetName())
			}
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
				reqParams = append(reqParams, fmt.Sprintf("%s: string", fieldName))

				// Extract the path parameter name from the tag
				re := regexp.MustCompile(`path:\"([^\"]+)\"`)
				if matches := re.FindStringSubmatch(field.Tag); len(matches) > 1 {
					pathParams[matches[1]] = fieldName
				} else {
					pathParams[strings.ToLower(field.Name)] = fieldName
				}
			} else if strings.Contains(field.Tag, "query:") {
				// Handle query parameters
				totalFields--
				reqParams = append(reqParams, fmt.Sprintf("%s: %s", fieldName, ConvertToTypeScriptType(builder, field.Type)))

				// Extract the query parameter name from the tag
				re := regexp.MustCompile(`query:\"([^\"]+)\"`)
				if matches := re.FindStringSubmatch(field.Tag); len(matches) > 1 {
					queryParams[fieldName] = matches[1]
				} else {
					queryParams[fieldName] = fieldName
				}
			}
		}
	}

	// Add any primitive parameters that appear before 'options' as path parameters
	primitiveParams := []string{}
	if len(reqParams) > 0 {
		for _, param := range reqParams {
			if !strings.Contains(param, "data:") {
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

	// Build query string for query parameters
	queryString := ""
	if len(queryParams) > 0 {
		queryString = "?"
		i := 0
		for paramName, queryName := range queryParams {
			if i > 0 {
				queryString += "&"
			}
			queryString += fmt.Sprintf("%s=${%s}", queryName, paramName)
			i++
		}
		route += queryString
	}

	// Format parameters after all path parameters have been processed
	params := strings.Join(reqParams, ", ")
	if request != "" {
		if params != "" {
			params += ", "
		}
		params += request
	}

	if responseType != nil {
		kind := util.ResponseGoTypeName(m, types.TypesPacket)
		if strings.HasPrefix(kind, "[]") || strings.HasPrefix(kind, "*[]") {
			response = fmt.Sprintf(": Promise<models.%s[]>", strings.TrimSpace(util.ToTitle(responseType.GetName())))
		} else {
			response = fmt.Sprintf(": Promise<models.%s>", strings.TrimSpace(util.ToTitle(responseType.GetName())))
		}
	} else {
		// Default to Promise<any> or a generic response type if responseType is nil
		response = ": Promise<any>" // Or Promise<models.GenericResponse> if you have one
	}

	// Use getLogicName to get the base name and append the HTTP method
	logicName := getLogicName(h)
	// Remove "Logic" suffix
	baseName := strings.TrimSuffix(logicName, "Logic")
	functionName := strings.ToLower(m.Method) + util.ToPascal(baseName)

	// Write the function definition
	fmt.Fprintf(endpointBuilder, "  %s: (%s)%s =>\n", util.FirstToLower(functionName), params, response)

	// Determine the proper indentation (1 tab/2 spaces)
	indentation := "    "

	// Determine response type name for the API call
	responseTypeName := "any" // Default if responseType is nil
	if responseType != nil {
		// what kind of response type is this?
		// is it an array?
		kind := util.ResponseGoTypeName(m, types.TypesPacket)
		if strings.HasPrefix(kind, "[]") || strings.HasPrefix(kind, "*[]") {
			responseTypeName = fmt.Sprintf("%s[]", strings.TrimSpace(util.ToTitle(responseType.GetName())))
		} else {
			responseTypeName = strings.TrimSpace(util.ToTitle(responseType.GetName()))
		}
	}

	// Write the API call
	fmt.Fprintf(endpointBuilder, "%sclient.%s<models.%s>(`%s`", indentation, strings.ToLower(m.Method), responseTypeName, route)

	// Add request parameter if needed
	if strings.ToLower(m.Method) == "get" {
		fmt.Fprintf(endpointBuilder, ")")
	} else if hasRequestObject {
		fmt.Fprintf(endpointBuilder, ", data)")
	} else {
		fmt.Fprintf(endpointBuilder, ")")
	}

	// Close the function
	fmt.Fprintf(endpointBuilder, ",\n")

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
		return "string" // Or Date, depending on preference
	case "time.Duration":
		return "number"
	case "any", "interface{}":
		return "any"
	default:
		if strings.HasPrefix(goType, "[]") {
			elementType := goType[2:]
			// Handle nested types like []*User or []User
			return fmt.Sprintf("%s[]", ConvertToTypeScriptType(builder, cleanTypeName(elementType)))
		}
		if strings.HasPrefix(goType, "map[") && strings.Contains(goType, "]") {
			keyValueTypes := goType[4:]
			parts := strings.SplitN(keyValueTypes, "]", 2)
			if len(parts) == 2 {
				keyType := ConvertToTypeScriptType(builder, parts[0])
				valueType := ConvertToTypeScriptType(builder, cleanTypeName(parts[1]))
				return fmt.Sprintf("Record<%s, %s>", keyType, valueType)
			}
		}
		// Assume custom type, clean and use PascalCase
		return util.ToTitle(cleanTypeName(goType))
	}
}

// findFieldType remains the same
func findFieldType(builder *SaaSBuilder, name string) *string {
	files, err := filepath.Glob(path.Join(builder.ServiceName, types.TypesDir, "*.go"))
	if err != nil {
		return nil
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			return nil
		}
		lines := strings.Split(string(content), "\n")
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "//") {
				continue
			}
			re := regexp.MustCompile(`^type\s+` + regexp.QuoteMeta(name) + `\s+`)
			if re.MatchString(line) {
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
