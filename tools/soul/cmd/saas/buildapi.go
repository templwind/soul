package saas

import (
	_ "embed"
	"fmt"
	"io"
	"os"
	"path"
	"regexp"
	"sort"
	"strings"

	"github.com/templwind/soul/tools/soul/internal/types"
	"github.com/templwind/soul/tools/soul/pkg/site/spec"
	"github.com/templwind/soul/tools/soul/pkg/util"
)

// buildApi processes and generates TypeScript interfaces from Go structs
func buildApi(builder *SaaSBuilder) error {
	allowedTypes := make(map[string]bool)

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

						writeApiEndpoint(endpointBuilder, requestType, responseType, srv, h, m, routePrefix)
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
		filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "api", "endpoints.ts")
		// fmt.Println("Removing:", filename)
		os.Remove(filename)
		// Generate the endpoints.ts file
		if err := builder.genFile(fileGenConfig{
			subdir:       path.Join(builder.ServiceName, types.SrcDir, "api"),
			templateFile: "templates/app/src/api/endpoints.ts.tpl",
			data:         builder.Data,
		}); err != nil {
			fmt.Println(util.WrapErr(err, "endpoints.ts generate error"))
		}
	}

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
		"bool", "string", "[]byte", "time.Time", "time.Duration":
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
		if !first {
			modelBuilder.WriteString("\n\n")
		}
		first = false
		if err := writeApiType(&modelBuilder, tp); err != nil {
			return util.WrapErr(err, tp.GetName()+" generate error")
		}
	}

	filename := path.Join(builder.Dir, builder.ServiceName, types.SrcDir, "api", "models.ts")
	// fmt.Println("Removing:", filename)
	os.Remove(filename)

	models := modelBuilder.String()
	// fmt.Println(models)

	builder.Data["Models"] = models

	// Generate the models.ts file
	if err := builder.genFile(fileGenConfig{
		subdir:       path.Join(builder.ServiceName, types.SrcDir, "api"),
		templateFile: "templates/app/src/api/models.ts.tpl",
		data:         builder.Data,
	}); err != nil {
		fmt.Println(util.WrapErr(err, "models.ts generate error"))
	}

	return nil
}

func writeApiEndpoint(endpointBuilder io.Writer, requestType, responseType spec.Type, srv spec.Service, h spec.Handler, m spec.Method, routePrefix string) error {

	var reqParams []string
	var request, response string
	var totalFields int
	if requestType != nil {
		totalFields = len(requestType.GetFields())

		// fmt.Println("RequestType:", requestType)
		for _, field := range requestType.GetFields() {
			// fmt.Println("Tag:", field.Tag)
			if strings.Contains(field.Tag, "path:") {
				totalFields--
				var fieldName string
				if len(field.Name) > 3 {
					fieldName = util.FirstToLower(field.Name)
				} else {
					fieldName = strings.ToLower(field.Name)
				}
				reqParams = append(reqParams, fmt.Sprintf("%s: %s", fieldName, ConvertToTypeScriptType(field.Type)))
			}
		}
		if totalFields > 0 {
			request = fmt.Sprintf("req: models.%s", util.ToTitle(m.RequestType.GetName()))
		}
	}

	// format params
	params := ""
	if len(reqParams) > 0 {
		params = strings.Join(reqParams, ", ")
		if request != "" {
			params += ", "
		}
	}

	if responseType != nil {
		response = fmt.Sprintf(": Promise<models.%s>", util.ToTitle(m.ResponseType.GetName()))
	}

	handlerName := strings.Replace(util.ToPascal(getHandlerName(h, &m)), "Handler", "", -1)

	fmt.Fprintf(endpointBuilder, "export function %s(%s%s)%s {\n", handlerName, params, request, response)
	util.WriteIndent(endpointBuilder, 1)

	re := regexp.MustCompile(`:(\w+)`)

	route := re.ReplaceAllString(path.Join("/", strings.TrimLeft(routePrefix, "/"), m.Route), "${$1}")

	if totalFields > 0 {
		fmt.Fprintf(endpointBuilder, "return api.%s<models.%s>(`%s`, req)", strings.ToLower(m.Method), util.ToTitle(m.ResponseType.GetName()), route)
	} else {
		fmt.Fprintf(endpointBuilder, "return api.%s<models.%s>(`%s`)", strings.ToLower(m.Method), util.ToTitle(m.ResponseType.GetName()), route)
	}
	fmt.Fprintf(endpointBuilder, "\n}\n\n")
	return nil
}

// writeApiType writes the TypeScript interface definition for a given type
func writeApiType(modelBuilder io.Writer, tp spec.Type) error {
	if tp != nil {
		fmt.Fprintf(modelBuilder, "export interface %s {\n", util.ToTitle(tp.GetName()))
		for _, member := range tp.GetFields() {
			isOptional := strings.Contains(member.Tag, "omitempty")
			fieldName := extractFieldName(member.Tag, member.Name)
			if err := WriteApiProperty(modelBuilder, fieldName, member.Type, isOptional, 1); err != nil {
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
func WriteApiProperty(writer io.Writer, name, tp string, isOptional bool, indent int) error {
	// Use a utility function to write indentation
	util.WriteIndent(writer, indent)

	// Remove pointer symbols
	tp = strings.ReplaceAll(tp, "*", "")

	// Convert Go-specific types to TypeScript
	tsType := ConvertToTypeScriptType(tp)

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
func ConvertToTypeScriptType(goType string) string {
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
			return fmt.Sprintf("%s[]", ConvertToTypeScriptType(elementType))
		}
		if strings.HasPrefix(goType, "map[") && strings.Contains(goType, "]") {
			keyValueTypes := goType[4:]
			parts := strings.SplitN(keyValueTypes, "]", 2)
			if len(parts) == 2 {
				keyType := ConvertToTypeScriptType(parts[0])
				valueType := ConvertToTypeScriptType(parts[1])
				return fmt.Sprintf("Record<%s, %s>", keyType, valueType)
			}
		}
		return goType
	}
}
