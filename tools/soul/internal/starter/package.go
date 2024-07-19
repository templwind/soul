package starter

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
)

type PackageJSON struct {
	Name            string            `json:"name,omitempty"`
	Private         bool              `json:"private,omitempty"`
	Version         string            `json:"version,omitempty"`
	Type            string            `json:"type,omitempty"`
	Scripts         map[string]string `json:"scripts,omitempty"`
	DevDependencies map[string]string `json:"devDependencies,omitempty"`
	Dependencies    map[string]string `json:"dependencies,omitempty"`
}

func (p PackageJSON) MarshalJSON() ([]byte, error) {
	type Alias PackageJSON
	alias := struct {
		*Alias
	}{
		Alias: (*Alias)(&p),
	}

	// Prevent encoding '&&' characters
	buf := &bytes.Buffer{}
	encoder := json.NewEncoder(buf)
	encoder.SetEscapeHTML(false)
	encoder.SetIndent("", "  ")
	err := encoder.Encode(alias)
	if err != nil {
		return nil, err
	}

	// Replace '\u0026\u0026' with '&&'
	b := bytes.ReplaceAll(buf.Bytes(), []byte(`\u0026\u0026`), []byte(`&&`))
	return b, nil
}

func updatePackageJSON(fullPath, fileName, framework string) error {
	// Read the existing package.json file
	file, err := os.Open(fileName)
	if err != nil {
		fmt.Println("Error opening package.json file:", err)
		return err
	}
	defer file.Close()

	var pkg PackageJSON
	err = json.NewDecoder(file).Decode(&pkg)
	if err != nil {
		fmt.Println("Error decoding package.json file:", err)
		return err
	}

	// check to see if the scripts map is nil
	if pkg.Scripts == nil {
		pkg.Scripts = make(map[string]string)
	}

	// Add or update script calls
	pkg.Scripts["build:watch"] = "tsc && vite build --watch"

	// Marshal the modified package JSON
	encodedJSON, err := pkg.MarshalJSON()
	if err != nil {
		fmt.Println("Error encoding package.json file:", err)
		return err
	}

	// Write the encoded JSON to the file
	file, err = os.Create(fileName)
	if err != nil {
		fmt.Println("Error creating package.json file:", err)
		return err
	}
	defer file.Close()

	_, err = file.Write(encodedJSON)
	if err != nil {
		fmt.Println("Error writing package.json file:", err)
		return err
	}

	fmt.Println("Successfully modified package.json")
	return nil
}
