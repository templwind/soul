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
	endpointBuilder := new(strings.Builder)
	// endpointBuilder.WriteString("\n\n")

	// Iterate through all services and methods to identify JSON-returning request and response types
	for _, s := range builder.Spec.Servers {
		routePrefix := strings.ToLower(s.GetAnnotation(types.PrefixProperty))
		// fmt.Println("RoutePrefix:", routePrefix)
		for _, srv := range s.Services {
			for _, h := range srv.Handlers {
			outerLoop:
				for _, m := range h.Methods {

					if m.IsSocket {
						for _, node := range m.SocketNode.Topics {

							if node.Topic != "" {
								// fmt.Println("Socket:", node.Topic)
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.Topic))] = node.Topic
							}
							if node.ResponseTopic != "" {
								// fmt.Println("Socket:", node.ResponseTopic)
								constants[util.ToPascal(fmt.Sprintf("Topic_%s", node.ResponseTopic))] = node.ResponseTopic
							}
						}
					}
					// fmt.Println(constants)

					if m.IsSocket && m.SocketNode != nil {
						for _, node := range m.SocketNode.Topics {
							// fmt.Println("Socket:", node.GetName(), node.RequestType, node.ResponseType)

							if node.RequestType != nil {
								allowedTypes[node.RequestType.GetName()] = true
							}
							if node.ResponseType != nil {
								allowedTypes[node.ResponseType.GetName()] = true
							}
						}
						// fmt.Println("Socket:", m.SocketNode)
					}

					// fmt.Println("Method:", m.GetName(), m.RequestType, m.ResponseType)
					// if m.RequestType != nil {
					// 	fmt.Println("Method:", m.RequestType.GetName(), m.GetName(), m.ReturnsJson)
					// }

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
								// fmt.Println("Field:", field.Name, field.Tag)
								if strings.Contains(field.Tag, "form:") && !strings.Contains(field.Tag, "json:") {
									continue outerLoop
								}
							}

							allowedTypes[m.RequestType.GetName()] = true

						}
						if m.ResponseType != nil {
							allowedTypes[m.ResponseType.GetName()] = true
							// fmt.Println("ResponseType:", m.ResponseType.GetName())
							responseType = findTypeByName(builder.Spec.Types, m.ResponseType.GetName())
						} else {
							fmt.Println("ResponseType not found:", m.ResponseType.GetName())
							continue outerLoop
						}

						writeApiEndpoint(builder, endpointBuilder, requestType, responseType, h, m, routePrefix)
						// fmt.Println("Endpoint:", endpointBuilder.String())
					}
				}
			}
		}
	}

	builder.Data["Endpoints"] = strings.TrimSpace(endpointBuilder.String())
	// fmt.Println("Endpoints:", builder.Data["Endpoints"])

	// fmt.Println(builder.Data["Endpoints"])
	if !builder.IsService {
		filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "endpoints.ts")
		// fmt.Println("Removing:", filename)
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
	// if allowedTypes[tp.GetName()] {
	// 	return // Avoid processing already visited types
	// }

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

		// fmt.Println("Field:", field.Name, fieldType)
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
		// fmt.Println("Writing:", key)
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
	// fmt.Println("Removing:", filename)
	os.Remove(filename)

	models := modelBuilder.String()
	// fmt.Println(models)

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
	// fmt.Println(constantsBuilder.String())

	builder.Data["Constants"] = constantsBuilder.String()

	filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "lib", "api", "constants.ts")
	// fmt.Println("Removing:", filename)
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

		// Only add request object if it's not a GET or if there are non-path fields
		if !strings.Contains(m.Route, ":") && totalFields > 0 && !(strings.ToUpper(m.Method) == "GET" && allFieldsArePath) {
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

	// Format parameters
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

	handlerName := strings.Replace(util.ToPascal(getHandlerName(h, &m)), "Handler", "", -1)
	fmt.Fprintf(endpointBuilder, "export function %s(%s)%s {\n", handlerName, params, response)
	util.WriteIndent(endpointBuilder, 1)

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
		}
	}

	// Replace path parameters in the route
	for param, varName := range pathParams {
		route = strings.ReplaceAll(route, ":"+param, "${"+varName+"}")
	}

	// Only append primitive parameters if they don't correspond to path parameters
	for _, param := range primitiveParams {
		// Check if this parameter is already used as a path parameter
		isPathParam := false
		for _, pathVar := range pathParams {
			if pathVar == param {
				isPathParam = true
				break
			}
		}
		if !isPathParam {
			route = fmt.Sprintf("%s/${%s}", route, param)
		}
	}

	// Append query parameters if present
	if len(queryParams) > 0 {
		route = fmt.Sprintf("%s?%s", route, strings.Join(queryParams, "&"))
	}

	method := strings.ToLower(m.Method)
	if method == "get" {
		fmt.Fprintf(endpointBuilder, "return api.%s<models.%s>(`%s`, undefined, options?.fetch)",
			method,
			util.ToTitle(m.ResponseType.GetName()),
			route)
	} else if hasRequestObject {
		fmt.Fprintf(endpointBuilder, "return api.%s<models.%s>(`%s`, req, undefined, options?.fetch)",
			method,
			util.ToTitle(m.ResponseType.GetName()),
			route)
	} else {
		fmt.Fprintf(endpointBuilder, "return api.%s<models.%s>(`%s`, undefined, undefined, options?.fetch)",
			method,
			util.ToTitle(m.ResponseType.GetName()),
			route)
	}

	fmt.Fprintf(endpointBuilder, "\n}\n\n")
	return nil
}

func findFieldType(builder *SaaSBuilder, name string) *string {
	// fmt.Println("Finding:", name)
	// search the types folder for files containing the type name
	files, err := filepath.Glob(path.Join(builder.ServiceName, types.TypesDir, "*.go"))
	if err != nil {
		return nil
	}
	for _, file := range files {
		// fmt.Println("Searching:", file)
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
					// fmt.Println("Found:", name, "in", file, "of type", out[0][2])
					// fmt.Printf("Type: %v\n", out[0])
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
	// fmt.Println("Converting:", goType)
	fieldType := findFieldType(builder, goType)
	if fieldType != nil {
		// fmt.Println("Member:", member.Name, member.Type, member.Tag)
		goType = *fieldType
		// fmt.Println("Converted:", goType)
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
