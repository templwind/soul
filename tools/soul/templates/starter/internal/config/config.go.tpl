package config

import (
	"embed"

	"github.com/goccy/go-yaml"
)

type Config struct {
    AppName 	      string   `yaml:"AppName"`
    DefaultDataDir    string   `yaml:"DefaultDataDir"`
    DatabaseFileName  string   `yaml:"DatabaseFileName"`
	RunMigrations     bool     `yaml:"RunMigrations"`
    MigrationsPath    string   `yaml:"MigrationsPath"`
	EmbededMigrations embed.FS `yaml:"-"`
	Auth             struct {
		TokenSecret   string `yaml:"TokenSecret"`
		TokenDuration string `yaml:"TokenDuration"`
	} `yaml:"Auth"`
	Setup           struct {
		DefaultAdmin struct {
			Name     string `yaml:"Name"`
			Username string `yaml:"Username"`
			Email    string `yaml:"Email"`
			Password string `yaml:"Password"`
		} `yaml:"DefaultAdmin"`
		TestUser struct {
			Name     string `yaml:"Name"`
			Username string `yaml:"Username"`
			Email    string `yaml:"Email"`
			Password string `yaml:"Password"`
		} `yaml:"TestUser"`
	} `yaml:"Setup"`
}
	
// This function now explicitly expects a pointer to Config rather than any type.
func LoadConfigFromYamlBytes(bytes []byte, cfg *Config) error {
	err := yaml.Unmarshal(bytes, cfg)
	if err != nil {
		return err
	}
	return nil
}
