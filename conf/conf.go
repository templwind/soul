package conf

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	"github.com/templwind/soul/conf/encoding"
)

var (
	loaders = map[string]func([]byte, any) error{
		".yaml": LoadFromYamlBytes,
		".yml":  LoadFromYamlBytes,
	}
)

// Load loads config into v from file, .json, .yaml and .yml are acceptable.
func Load(file string, v any, opts ...Option) error {
	var err error
	var opt options
	for _, o := range opts {
		o(&opt)
	}

	var content []byte
	if opt.hasFS {
		content, err = opt.fs.ReadFile(file)
		if err != nil {
			panic(err)
		}
	} else {
		content, err = os.ReadFile(file)
		if err != nil {
			return err
		}
	}

	loader, ok := loaders[strings.ToLower(path.Ext(file))]
	if !ok {
		return fmt.Errorf("unrecognized file type: %s", file)
	}

	if opt.env {
		return loader([]byte(os.ExpandEnv(string(content))), v)
	}

	return loader(content, v)
}

// LoadFromJsonBytes loads config into v from content json bytes.
func LoadFromJsonBytes(content []byte, v any) error {
	if err := json.Unmarshal(content, v); err != nil {
		return err
	}

	if _, err := json.MarshalIndent(v, "", "  "); err != nil {
		return err
	}
	return nil
}

// LoadFromTomlBytes loads config into v from content toml bytes.
func LoadFromTomlBytes(content []byte, v any) error {
	b, err := encoding.TomlToJson(content)
	if err != nil {
		return err
	}

	return LoadFromJsonBytes(b, v)
}

// LoadFromYamlBytes loads config into v from content yaml bytes.
func LoadFromYamlBytes(content []byte, v any) error {
	b, err := encoding.YamlToJson(content)
	if err != nil {
		return err
	}

	return LoadFromJsonBytes(b, v)
}

// LoadConfigFromYamlBytes loads config into v from content yaml bytes.
// Deprecated: use LoadFromYamlBytes instead.
func LoadConfigFromYamlBytes(content []byte, v any) error {
	return LoadFromYamlBytes(content, v)
}

// MustLoad loads config into v from path, exits on error.
func MustLoad(path string, v any, opts ...Option) {
	if err := Load(path, v, opts...); err != nil {
		log.Fatalf("error: config file %s, %s", path, err.Error())
	}
}
