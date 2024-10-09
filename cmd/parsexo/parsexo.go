package parsexo

import (
	"bufio"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"text/template"
	"unicode"

	"github.com/spf13/cobra"
	"github.com/zeromicro/go-zero/core/stores/builder"
	"github.com/zeromicro/go-zero/core/stringx"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

var xoOnly = true
var inputPath, outputPath string
var additionalIgnoreTypes []string
var baseImportPath string

var ignoreTypes = map[string]bool{
	"ErrInsertFailed": true,
	"Error":           true,
	"ErrUpdateFailed": true,
	"ErrUpsertFailed": true,
	// Add other types to ignore as needed
}

const (
	duplicateFunctionMarker = "Xo"
)

func Cmd() *cobra.Command {

	var cmd = &cobra.Command{
		Use:   "parsexo",
		Short: "Parse .xo.go files",
		Run: func(cmd *cobra.Command, args []string) {
			for _, typeName := range additionalIgnoreTypes {
				ignoreTypes[typeName] = true
			}
			// Resolve the absolute paths of input and output directories
			absInputPath, err := filepath.Abs(inputPath)
			if err != nil {
				fmt.Printf("Error resolving absolute path of input directory: %v\n", err)
				return
			}

			absOutputPath, err := filepath.Abs(outputPath)
			if err != nil {
				fmt.Printf("Error resolving absolute path of output directory: %v\n", err)
				return
			}

			// Find the go.mod file for the source file
			goModPath, _ := findGoModPath(filepath.Dir(absInputPath))
			// Extract module name from go.mod
			moduleName, _ := getModuleName(goModPath)

			err = generateStaticFiles(moduleName, absOutputPath)
			if err != nil {
				fmt.Printf("Error resolving absolute path of output directory: %v\n", err)
				return
			}

			fmt.Println("Parsing .xo.go files in:", absInputPath)
			err = filepath.Walk(absInputPath, func(path string, info os.FileInfo, err error) error {
				if err != nil {
					return err
				}
				if strings.HasSuffix(path, ".xo.go") {
					if strings.Contains(path, "/sf_") {
						fmt.Println("Not attempting to parse sf file:", path)
						return nil
					}
					err := processXoFile(path, absOutputPath, ignoreTypes)
					if err != nil {
						fmt.Println("Error parsing file:", path)
						return err
					}
				}
				return nil
			})
			if err != nil {
				fmt.Println("Error parsing files:", err)
			}
		},
	}

	cmd.Flags().StringVarP(&inputPath, "input", "i", "", "Input directory path")
	cmd.Flags().StringVarP(&outputPath, "output", "o", "", "Output directory path")
	cmd.Flags().StringSliceVarP(&additionalIgnoreTypes, "ignore-types", "t", []string{}, "Additional types to ignore")
	cmd.Flags().StringVarP(&baseImportPath, "import-path", "b", "", "Base import path for the generated files")

	// Mark the 'input' and 'output' flags as required
	err := cmd.MarkFlagRequired("input")
	if err != nil {
		fmt.Println("Error marking 'input' as required:", err)
	}

	err = cmd.MarkFlagRequired("output")
	if err != nil {
		fmt.Println("Error marking 'output' as required:", err)
	}

	err = cmd.MarkFlagRequired("import-path")
	if err != nil {
		fmt.Println("Error marking 'import-path' as required:", err)
	}

	return cmd
}

// Check if the file contains an enum declaration.
func containsEnumDeclaration(node *ast.File) bool {
	for _, f := range node.Decls {
		genDecl, ok := f.(*ast.GenDecl)
		if !ok {
			continue
		}
		if genDecl.Tok == token.CONST {
			return true
		}
	}
	return false
}

// Check if a file contains any ignored types.
func containsIgnoredType(node *ast.File, ignoredTypes map[string]bool) bool {
	for _, f := range node.Decls {
		genDecl, ok := f.(*ast.GenDecl)
		if !ok {
			continue
		}
		for _, spec := range genDecl.Specs {
			typeSpec, ok := spec.(*ast.TypeSpec)
			if !ok {
				continue
			}
			if _, ok := ignoredTypes[typeSpec.Name.Name]; ok {
				return true
			}
		}
	}
	return false
}

func processXoFile(filename string, outputPath string, ignoredTypes map[string]bool) error {
	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, filename, nil, parser.ParseComments)
	if err != nil {
		return err
	}

	// Skip processing if the file contains an enum declaration
	if containsEnumDeclaration(node) {
		fmt.Printf("Skipping file %s as it contains enum declaration\n", filename)
		return nil

	}

	// Skip processing if the file contains an ignored type.
	if containsIgnoredType(node, ignoredTypes) {
		fmt.Printf("Skipping file %s as it contains ignored types\n", filename)
		return nil
	}

	// Initialize a map to track function names
	functionNameMap := make(map[string]struct{})

	var functions []FunctionInfo
	var functionSignatures []string // Store function signatures as strings
	var tableName string

	// Loop through the declarations in the file
	for _, f := range node.Decls {
		fn, ok := f.(*ast.FuncDecl)
		if !ok {
			continue
		}

		// Check for duplicate function names
		if _, exists := functionNameMap[fn.Name.Name]; exists {
			// rename the function name
			fn.Name.Name = fn.Name.Name + duplicateFunctionMarker
		}

		// Add the function name to the map
		functionNameMap[fn.Name.Name] = struct{}{}

		isReceiver := fn.Recv != nil && len(fn.Recv.List) > 0
		functions = append(functions, FunctionInfo{
			Decl:       fn,
			IsReceiver: isReceiver,
		})
	}

	// Directly inspect all comments
	for _, commentGroup := range node.Comments {
		for _, comment := range commentGroup.List {
			// Look for a comment that starts with "represents a row from"
			if strings.Contains(comment.Text, "represents a row from") {
				// Extract the table name from the comment
				parts := strings.Split(comment.Text, "'")
				if len(parts) >= 3 {
					tableName = parts[1] // The table name is between the single quotes
					break
				}
			}
		}

		// Break the outer loop if table name is found
		if tableName != "" {
			break
		}
	}

	// Use the filename or struct name to generate modelName
	// Get the struct name from the AST
	modelName, err := getStructNameFromAstFile(node)
	if err != nil {
		return err
	}
	fieldNames, rows, rowsExpectAutoSet, rowsWithPlaceHolder, rowsWithNamedPlaceHolder := extractFieldData(node)

	inputPackageName := getLastPathComponent(inputPath)

	// Find the go.mod file for the source file
	goModPath, err := findGoModPath(filepath.Dir(filename))
	if err != nil {
		return fmt.Errorf("error finding go.mod: %v", err)
	}

	// Extract module name from go.mod
	moduleName, err := getModuleName(goModPath)
	if err != nil {
		return fmt.Errorf("error getting module name from go.mod: %v", err)
	}

	// Get the relative path from the module root to the source file's directory
	moduleDir := filepath.Dir(goModPath)
	relativePath, err := filepath.Rel(moduleDir, filepath.Dir(filename))
	if err != nil {
		return fmt.Errorf("error finding relative path: %v", err)
	}

	// Replace OS-specific path separators with slashes for consistent package naming
	relativePath = strings.ReplaceAll(relativePath, string(os.PathSeparator), "/")

	// Concatenate the module name and the relative path to form the full package name
	fullPackageName := moduleName
	if relativePath != "." {
		fullPackageName += "/" + relativePath
	}

	// fmt.Println("Full Package Name: ", fullPackageName)

	return generateModelCode(modelName, fullPackageName, node, functions, functionSignatures, inputPackageName, fieldNames, rows, rowsExpectAutoSet, rowsWithPlaceHolder, rowsWithNamedPlaceHolder, outputPath, tableName)
}

func getLastPathComponent(path string) string {
	parts := strings.Split(filepath.Clean(path), string(os.PathSeparator))
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return ""
}

func getStructNameFromAstFile(node *ast.File) (string, error) {
	// Loop through the declarations to find the struct
	for _, f := range node.Decls {
		if genDecl, ok := f.(*ast.GenDecl); ok {
			for _, spec := range genDecl.Specs {
				if typeSpec, ok := spec.(*ast.TypeSpec); ok {
					if _, ok := typeSpec.Type.(*ast.StructType); ok {
						return typeSpec.Name.Name, nil // Return struct name
					}
				}
			}
		}
	}

	return "", fmt.Errorf("no struct found in file")
}

func exprToString(expr ast.Expr) string {
	switch e := expr.(type) {
	case *ast.Ident:
		return e.Name
	case *ast.SelectorExpr:
		return exprToString(e.X) + "." + e.Sel.Name
	case *ast.StarExpr:
		return "*" + exprToString(e.X)
	case *ast.ArrayType:
		return "[]" + exprToString(e.Elt)
	default:
		return ""
	}
}

func extractFieldData(file *ast.File) ([]string, string, string, string, string) {
	var fieldNames []string

	// Loop through the declarations in the file
	for _, decl := range file.Decls {
		// Check if the declaration is a GenDecl (general declaration)
		genDecl, ok := decl.(*ast.GenDecl)
		if !ok {
			continue
		}

		// Loop through the specifications in the declaration
		for _, spec := range genDecl.Specs {
			// Check if the spec is a TypeSpec (type specification)
			typeSpec, ok := spec.(*ast.TypeSpec)
			if !ok {
				continue
			}

			// Check if the type spec is a struct type
			structType, ok := typeSpec.Type.(*ast.StructType)
			if !ok {
				continue
			}

			// Loop through the fields in the struct type
			for _, field := range structType.Fields.List {
				// Extract the tag, assuming `db` tag is used
				if field.Tag != nil {
					tag := reflect.StructTag(strings.Trim(field.Tag.Value, "`"))
					dbName := tag.Get("db")
					if dbName != "" {
						fieldNames = append(fieldNames, dbName)
					}
				}
			}
		}
	}

	fieldNamesStr := strings.Join(fieldNames, ",")
	rowsExpectAutoSet := strings.Join(stringx.Remove(fieldNames, "id"), ",")
	rowsWithPlaceHolder := builder.PostgreSqlJoin(stringx.Remove(fieldNames, "id"))
	// Logic for named placeholders
	var namedPlaceholders []string
	for _, fieldName := range stringx.Remove(fieldNames, "id") {
		namedPlaceholders = append(namedPlaceholders, fieldName+" = :"+fieldName)
	}
	rowsWithNamedPlaceHolder := strings.Join(namedPlaceholders, ", ")

	return fieldNames, fieldNamesStr, rowsExpectAutoSet, rowsWithPlaceHolder, rowsWithNamedPlaceHolder
}

type FunctionInfo struct {
	Decl       *ast.FuncDecl
	IsReceiver bool
}

// Create a function to generate the function return types map
func makeFunctionReturnTypesMap(functions []FunctionInfo) map[string]string {
	functionReturnTypes := make(map[string]string)
	for _, fn := range functions {
		functionReturnTypes[fn.Decl.Name.Name] = getFunctionReturnType(fn.Decl, "")
	}
	return functionReturnTypes
}

type defaultInterfaceTemplateData struct {
	FullPackageName          string
	OriginalPackageName      string
	IncludePackageName       string
	UsesSqlNull              bool
	UsesResourcesTypes       bool
	ModelName                string
	FunctionSignatures       []string
	Functions                []FunctionInfo
	FieldNames               []string
	Rows                     string
	RowsExpectAutoSet        string
	RowsWithPlaceHolder      string
	RowsWithNamedPlaceHolder string
	FunctionReturnTypes      map[string]string
	TypeMethods              map[string]bool
	TableName                string
	BaseImportPath           string
}

func generateStaticFiles(packageName, outputPath string) error {
	// Extract the package name from the output path
	outputPathBase := filepath.Base(outputPath)
	includePackageName := cases.Lower(language.English).String(outputPathBase) // Ensure the package name is in lowercase

	// Ensure the output directory exists
	err := os.MkdirAll(outputPath, os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed to create output directory: %v", err)
	}

	// Create the data for the template
	data := defaultInterfaceTemplateData{
		// FullPackageName:          fullPackageName,
		// OriginalPackageName:      originalPackageName,
		IncludePackageName: includePackageName,
		BaseImportPath:     baseImportPath,
	}

	funcMap := template.FuncMap{
		"FirstChar":                     firstChar,
		"GetFunctionParams":             getFunctionParams,
		"GetFunctionCleanParams":        getFunctionCleanParams,
		"RemoveDuplicateFunctionMarker": removeDuplicateFunctionMarker,
		"GetFunctionReturnType":         getFunctionReturnType,
		"FirstToLower":                  firstToLower,
		"FormatTableName":               formatTableName,
		"FormatFieldNames":              formatFieldNames,
		"WrapInBackticks":               wrapInBackticks,
		"InsertBacktick":                insertBacktick,
		"RawTableName":                  rawTableName,
	}

	filePath := filepath.Join(inputPath, "transactions.ext.go")
	file, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("failed to create transaction file: %v", err)
	}
	defer file.Close()

	// Parse the template
	tmpl, err := template.New("transaction").Funcs(funcMap).Parse(TransactionTemplate)
	if err != nil {
		return fmt.Errorf("failed to parse template for extension: %v", err)
	}
	// Execute the template with the data struct
	err = tmpl.Execute(file, data)
	if err != nil {
		return fmt.Errorf("failed to execute template for transactions: %v", err)
	}
	return nil
}

func generateModelCode(modelName, fullPackageName string, node *ast.File, functions []FunctionInfo, functionSignatures []string, originalPackageName string, fieldNames []string, rows, rowsExpectAutoSet, rowsWithPlaceHolder, rowsWithNamedPlaceHolder, outputPath, tableName string) error {
	// Extract the package name from the output path
	outputPathBase := filepath.Base(outputPath)
	includePackageName := cases.Lower(language.English).String(outputPathBase) // Ensure the package name is in lowercase

	// Ensure the output directory exists
	err := os.MkdirAll(outputPath, os.ModePerm)
	if err != nil {
		return fmt.Errorf("failed to create output directory: %v", err)
	}

	// Check for SQL null types in the AST node
	usesSqlNull := containsSqlNullTypes(node)
	usesResourcesTypes := containsResourcesTypes(node)

	// Create the data for the template
	data := defaultInterfaceTemplateData{
		FullPackageName:          fullPackageName,
		OriginalPackageName:      originalPackageName,
		IncludePackageName:       includePackageName,
		UsesSqlNull:              usesSqlNull,
		UsesResourcesTypes:       usesResourcesTypes,
		ModelName:                modelName,
		FunctionSignatures:       functionSignatures,
		Functions:                functions,
		FieldNames:               fieldNames,
		Rows:                     rows,
		RowsExpectAutoSet:        rowsExpectAutoSet,
		RowsWithPlaceHolder:      rowsWithPlaceHolder,
		RowsWithNamedPlaceHolder: rowsWithNamedPlaceHolder,
		FunctionReturnTypes:      makeFunctionReturnTypesMap(functions),
		TableName:                tableName,
		BaseImportPath:           baseImportPath,
	}

	funcMap := template.FuncMap{
		"FirstChar":                     firstChar,
		"GetFunctionParams":             getFunctionParams,
		"GetFunctionCleanParams":        getFunctionCleanParams,
		"RemoveDuplicateFunctionMarker": removeDuplicateFunctionMarker,
		"GetFunctionReturnType":         getFunctionReturnType,
		"FirstToLower":                  firstToLower,
		"FormatTableName":               formatTableName,
		"FormatFieldNames":              formatFieldNames,
		"WrapInBackticks":               wrapInBackticks,
		"InsertBacktick":                insertBacktick,
		"RawTableName":                  rawTableName,
	}

	fmt.Println("Generating model code for:", modelName)
	{

		if xoOnly {

			extensionFilePath := filepath.Join(inputPath, fmt.Sprintf("%s.ext.go", strings.ToLower(modelName)))
			extensionFile, err := os.Create(extensionFilePath)
			if err != nil {
				return fmt.Errorf("failed to create extension file: %v", err)
			}
			defer extensionFile.Close()

			// Parse the template
			extTmpl, err := template.New("model").Funcs(funcMap).Parse(XoExtensionTemplate)
			if err != nil {
				return fmt.Errorf("failed to parse template for extension: %v", err)
			}
			// Execute the template with the data struct
			err = extTmpl.Execute(extensionFile, data)
			if err != nil {
				return fmt.Errorf("failed to execute template for extension: %v", err)
			}
			return nil
		}

		// Create the output file
		outputFilePath := filepath.Join(outputPath, fmt.Sprintf("%s_model.gen.go", toSnakeCase(modelName)))
		outputFile, err := os.Create(outputFilePath)
		if err != nil {
			return fmt.Errorf("failed to create output file: %v", err)
		}
		defer outputFile.Close()

		// Parse the template
		tmpl, err := template.New("model").Funcs(funcMap).Parse(DefaultInterfaceTemplate)
		if err != nil {
			return fmt.Errorf("failed to parse template: %v", err)
		}

		// Execute the template with the data struct
		err = tmpl.Execute(outputFile, data)
		if err != nil {
			return fmt.Errorf("failed to execute template: %v", err)
		}

		fmt.Printf("Generated model code at %s\n", outputFilePath)
	}

	// Generate custom interface template here
	{
		// Create the output file
		outputFilePath := filepath.Join(outputPath, fmt.Sprintf("%s_model.go", toSnakeCase(modelName)))
		// if the outputFilePath already exists then skip
		if _, err := os.Stat(outputFilePath); !os.IsNotExist(err) {
			fmt.Printf("Skipping generation of custom model code at %s\n", outputFilePath)
			return nil
		}

		outputFile, err := os.Create(outputFilePath)
		if err != nil {
			return fmt.Errorf("failed to create output file: %v", err)
		}
		defer outputFile.Close()

		// Parse the template
		tmpl, err := template.New("model").Funcs(funcMap).Parse(CustomInterfaceTemplate)
		if err != nil {
			return fmt.Errorf("failed to parse template: %v", err)
		}
		// Execute the template with the data struct
		err = tmpl.Execute(outputFile, data)
		if err != nil {
			return fmt.Errorf("failed to execute template: %v", err)
		}

		fmt.Printf("Generated model code at %s\n", outputFilePath)
	}
	return nil
}

// toSnakeCase converts a PascalCase string to snake_case.
func toSnakeCase(str string) string {
	var result strings.Builder
	for i, r := range str {
		if i > 0 && unicode.IsUpper(r) && !unicode.IsUpper(rune(str[i-1])) && str[i-1] != '_' {
			result.WriteRune('_')
		}
		result.WriteRune(unicode.ToLower(r))
	}
	return result.String()
}

func firstToLower(s string) string {
	if len(s) == 0 {
		return s
	}

	var i int
	for i = 1; i < len(s); i++ {
		if i+1 < len(s) && unicode.IsUpper(rune(s[i])) && unicode.IsLower(rune(s[i+1])) {
			break
		}
	}

	return strings.ToLower(s[:i]) + s[i:]
}

func findGoModPath(startDir string) (string, error) {
	currentDir := startDir
	for {
		// Check if go.mod exists in the current directory
		goModPath := filepath.Join(currentDir, "go.mod")
		if _, err := os.Stat(goModPath); err == nil {
			return goModPath, nil
		} else if !os.IsNotExist(err) {
			// An error other than "not exist"
			return "", err
		}

		// Move to the parent directory
		parentDir := filepath.Dir(currentDir)
		if parentDir == currentDir {
			// Root directory reached without finding go.mod
			return "", os.ErrNotExist
		}
		currentDir = parentDir
	}
}

func getModuleName(goModPath string) (string, error) {
	file, err := os.Open(goModPath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "module") {
			parts := strings.Fields(line)
			if len(parts) >= 2 {
				return parts[1], nil
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}

	return "", fmt.Errorf("module directive not found in %s", goModPath)
}

func getFunctionParams(fn *ast.FuncDecl, originalPkg string, isReceiver bool, modelName string) string {
	params := make([]string, 0)
	for _, p := range fn.Type.Params.List {
		paramType := exprToStringWithPkg(p.Type, originalPkg)

		// Check if the parameter type is a pointer
		if _, ok := p.Type.(*ast.StarExpr); ok {
			paramType = "*" + paramType
		}

		for _, name := range p.Names {
			if !strings.Contains(paramType, "DB") {
				params = append(params, name.Name+" "+paramType)
			}
		}
	}

	if isReceiver {
		// Include the model object as the first parameter for receiver functions
		receiverType := modelName
		if originalPkg != "" {
			receiverType = originalPkg + "." + modelName
		}

		// make the modelName have a lowercase first letter
		modelName = firstToLower(modelName)
		params = append(params, fmt.Sprintf("%s *%s", modelName, receiverType))
	}

	return strings.Join(params, ", ")
}

func getFunctionCleanParams(fn *ast.FuncDecl, useAdapter bool) string {
	var params []string
	for _, p := range fn.Type.Params.List {
		for _, name := range p.Names {
			paramType := exprToStringWithPkg(p.Type, "")
			if strings.Contains(paramType, "DB") {
				if useAdapter {
					params = append(params, "db")
				} else {
					params = append(params, "m.transaction.db")
				}
			} else {
				params = append(params, name.Name)
			}
		}
	}
	return strings.Join(params, ", ")
}

func removeDuplicateFunctionMarker(fn *ast.FuncDecl) string {
	return strings.ReplaceAll(fn.Name.Name, duplicateFunctionMarker, "")
}

func getFunctionReturnType(fn *ast.FuncDecl, originalPkg string) string {
	if fn.Type.Results == nil {
		return ""
	}

	var packageName string
	if originalPkg != "" {
		packageName = originalPkg + "."
	}

	results := make([]string, 0)
	for _, r := range fn.Type.Results.List {
		resultType := exprToStringWithPkg(r.Type, packageName)

		// replace .. with .
		resultType = strings.ReplaceAll(resultType, "..", ".")

		results = append(results, resultType)
	}

	// Check the number of return types
	numResults := len(results)
	if numResults == 1 {
		// Single return type
		return results[0]
	} else if numResults > 1 {
		// Multiple return types
		return "(" + strings.Join(results, ", ") + ")"
	} else {
		// No return types
		return ""
	}
}

func exprToStringWithPkg(expr ast.Expr, packageName string) string {
	switch e := expr.(type) {
	case *ast.Ident:
		typeName := e.Name
		// If it's a native Go type or an ignored type, return as is.
		if isNativeType(typeName) || ignoreTypes[typeName] {
			return typeName
		}
		// Prepend the package name if it's a non-native type and the package name is provided.
		if packageName != "" {
			return packageName + "." + typeName
		}
		return typeName
	case *ast.SelectorExpr:
		// Handle selector expressions.
		fullTypeName := exprToString(e.X) + "." + e.Sel.Name
		if ignoreTypes[fullTypeName] {
			return fullTypeName
		}
		// Check if it already represents a package name.
		if xIdent, ok := e.X.(*ast.Ident); ok {
			if isPackageName(xIdent.Name) {
				return fullTypeName
			}
		}
		// If not a package identifier, prepend the package name if provided.
		if packageName != "" {
			return packageName + "." + fullTypeName
		}
		return fullTypeName
	case *ast.StarExpr:
		// For pointer types, add '*' and process the element type.
		return "*" + exprToStringWithPkg(e.X, packageName)
	case *ast.ArrayType:
		// For array types, add '[]' and process the element type.
		return "[]" + exprToStringWithPkg(e.Elt, packageName)
	default:
		return ""
	}
}

// isPackageName checks if the provided name is a known package name
func isPackageName(name string) bool {
	// Check if the name contains a dot, indicating it might be a package or type name from a package
	if strings.Contains(name, ".") {
		return true
	}

	// Check if the name is not a native type and if it begins with a lowercase letter
	if !isNativeType(name) && unicode.IsLower(rune(name[0])) {
		return true
	}

	return false
}

// isNativeType checks if the provided type name is a native Go type
func isNativeType(typeName string) bool {
	nativeTypes := map[string]bool{
		"string": true, "int": true, "int8": true, "int16": true,
		"int32": true, "int64": true, "uint": true, "uint8": true,
		"uint16": true, "uint32": true, "uint64": true, "uintptr": true,
		"byte": true, "rune": true, "float32": true, "float64": true,
		"complex64": true, "complex128": true, "bool": true, "error": true,
		"interface{}": true,
		// Standard library types
		"context.Context": true,
		// Add other standard library types as needed
	}
	_, exists := nativeTypes[typeName]
	return exists
}

func containsSqlNullTypes(node *ast.File) bool {
	// Named recursive function
	var checkType func(ast.Expr) bool
	checkType = func(expr ast.Expr) bool {
		switch e := expr.(type) {
		case *ast.SelectorExpr:
			if pkgIdent, ok := e.X.(*ast.Ident); ok {
				// Check for "sql" package and "Null" prefix in type
				if pkgIdent.Name == "sql" && strings.HasPrefix(e.Sel.Name, "Null") {
					return true
				}
			}
		case *ast.StarExpr:
			// Recursively check the element type for *ast.StarExpr
			return checkType(e.X)
		case *ast.ArrayType:
			// Recursively check the element type for *ast.ArrayType
			return checkType(e.Elt)
		}
		return false
	}

	// Define checkSqlNullType using the named recursive function
	checkSqlNullType := func(expr ast.Expr) bool {
		return checkType(expr)
	}

	// Check each function declaration for sql.Null* types
	for _, decl := range node.Decls {
		fn, ok := decl.(*ast.FuncDecl)
		if !ok {
			continue
		}

		// Check parameters for sql.Null* types
		if fn.Type.Params != nil {
			for _, p := range fn.Type.Params.List {
				if checkSqlNullType(p.Type) {
					return true
				}
			}
		}

		// Check return types for sql.Null* types
		if fn.Type.Results != nil {
			for _, r := range fn.Type.Results.List {
				if checkSqlNullType(r.Type) {
					return true
				}
			}
		}
	}
	return false
}

func containsResourcesTypes(node *ast.File) bool {
	// Named recursive function
	var checkType func(ast.Expr) bool
	checkType = func(expr ast.Expr) bool {
		switch e := expr.(type) {
		case *ast.SelectorExpr:
			if pkgIdent, ok := e.X.(*ast.Ident); ok {
				// Check for "resources" package
				if pkgIdent.Name == "resource" {
					return true
				}
			}
		case *ast.StarExpr:
			// Recursively check the element type for *ast.StarExpr
			return checkType(e.X)
		case *ast.ArrayType:
			// Recursively check the element type for *ast.ArrayType
			return checkType(e.Elt)
		}
		return false
	}

	// Define checkResourcesType using the named recursive function
	checkResourcesType := func(expr ast.Expr) bool {
		return checkType(expr)
	}

	// Check each function declaration for "resources" package types
	for _, decl := range node.Decls {
		fn, ok := decl.(*ast.FuncDecl)
		if !ok {
			continue
		}

		// Check parameters for "resources" package types
		if fn.Type.Params != nil {
			for _, p := range fn.Type.Params.List {
				if checkResourcesType(p.Type) {
					return true
				}
			}
		}

		// Check return types for "resources" package types
		if fn.Type.Results != nil {
			for _, r := range fn.Type.Results.List {
				if checkResourcesType(r.Type) {
					return true
				}
			}
		}
	}
	return false
}

func formatTableName(tableName string) string {
	parts := strings.Split(tableName, ".")
	// Check if the tableName is split into two parts (schema and table name)
	if len(parts) == 2 {
		// Format and return the table name with each part enclosed in double quotes, and the whole thing in backticks
		return fmt.Sprintf("`\"%s\"`", parts[1])
	}
	// Return the original table name if it's not in the expected format
	return tableName
}

func rawTableName(tableName string) string {
	parts := strings.Split(tableName, ".")
	// Check if the tableName is split into two parts (schema and table name)
	if len(parts) == 2 {
		// Format and return the table name with each part enclosed in double quotes, and the whole thing in backticks
		return fmt.Sprintf("%s", parts[1])
	}
	// Return the original table name if it's not in the expected format
	return tableName
}

func formatFieldNames(fieldNames []string) string {

	// format the fieldnemaes into an array of strings
	var formattedFieldNames []string
	for _, fieldName := range fieldNames {
		formattedFieldNames = append(formattedFieldNames, fmt.Sprintf("\"%s\"", fieldName))
	}

	// return the formatted fieldnames as a string
	return `[]string{` + strings.Join(formattedFieldNames, ",") + `}`
}

func wrapInBackticks(str string) string {
	return fmt.Sprintf("`%s`", str)
}

func insertBacktick() string {
	return "`"
}

// FirstChar returns the first character of a string.
func firstChar(s string) string {
	if len(s) == 0 {
		return ""
	}
	return strings.ToLower(string(s[0]))
}
