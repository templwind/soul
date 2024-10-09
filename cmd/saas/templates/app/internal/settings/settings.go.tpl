package settings

import (
	"sort"
	"strings"

	"{{ .serviceName }}/internal/models"
)

type SettingType string

const (
	UserSettings    SettingType = "user"
	AccountSettings SettingType = "account"
)

// Setting represents an individual configuration setting.
type Setting struct {
	ID          int64    `yaml:"-"`
	Order       int      `yaml:"order"`
	Key         string   `yaml:"key"`
	Value       string   `yaml:"value"`
	Name        string   `yaml:"name"`
	Description string   `yaml:"description"`
	Category    string   `yaml:"category"`
	Required    bool     `yaml:"required"`
	Disabled    bool     `yaml:"disabled"`
	Kind        string   `yaml:"kind"`
	Options     []string `yaml:"options"`
	Scope       string   `yaml:"scope"`
}

type MergedSetting struct {
	Setting
	Enabled bool
	Color   string
}

// IsEnabled checks if the setting is enabled.
func (s *MergedSetting) IsEnabled() bool {
	if strings.TrimSpace(s.Value) == "" {
		s.Enabled = false
		s.Color = "toggle-primary"
		return false
	}
	s.Enabled = true
	s.Color = "toggle-success"
	return true
}

// Settings struct contains both account and user-specific settings.
type Settings struct {
	AccountSettings []CategorySettings
	UserSettings    []CategorySettings
}

// CategorySettings represents a category of settings.
type CategorySettings struct {
	Category string
	Order    int
	Items    []Setting
}

// New initializes the settings package with default values.
func New(accountSettings, userSettings []CategorySettings) *Settings {
	return &Settings{
		AccountSettings: accountSettings,
		UserSettings:    userSettings,
	}
}

// GetSetting retrieves a single setting by key, merging account and user-specific settings.
func (s *Settings) GetSetting(key string, modelSettings []*models.Setting, settingType SettingType) *MergedSetting {
	mergedSettings := s.Merge(modelSettings, settingType)

	for _, setting := range mergedSettings {
		if setting.Key == key {
			return &setting
		}
	}

	return nil
}

// Merge merges account settings with user-specific settings, giving precedence to the user-specific ones.
func (s *Settings) Merge(modelSettings []*models.Setting, settingType SettingType) []MergedSetting {
	mergedSettingsMap := make(map[string]Setting)

	var settingsToMerge []CategorySettings
	if settingType == AccountSettings {
		settingsToMerge = s.AccountSettings
	} else if settingType == UserSettings {
		settingsToMerge = s.UserSettings
	}

	for _, category := range settingsToMerge {
		for _, setting := range category.Items {
			setting.Category = category.Category
			mergedSettingsMap[setting.Key] = setting
		}
	}

	for _, setting := range modelSettings {
		if existingSetting, exists := mergedSettingsMap[setting.Key]; exists {
			existingSetting.ID = setting.ID
			existingSetting.Value = setting.Value
			mergedSettingsMap[setting.Key] = existingSetting
		}
	}

	var mergedSettings []MergedSetting
	for _, setting := range mergedSettingsMap {
		enabled := strings.TrimSpace(setting.Value) != ""
		mergedSettings = append(mergedSettings, MergedSetting{
			Setting: setting,
			Enabled: enabled,
		})
	}

	return mergedSettings
}

// GroupSettings groups merged settings by category and sorts them by order within each category.
func (s *Settings) GroupSettings(modelSettings []*models.Setting, settingType SettingType) map[string][]MergedSetting {
	mergedSettings := s.Merge(modelSettings, settingType)

	groupedSettings := make(map[string][]MergedSetting)

	for _, setting := range mergedSettings {
		groupedSettings[setting.Category] = append(groupedSettings[setting.Category], setting)
	}

	for category, settings := range groupedSettings {
		sort.Slice(settings, func(i, j int) bool {
			return settings[i].Order < settings[j].Order
		})
		groupedSettings[category] = settings
	}

	return groupedSettings
}

// SubCategory represents a subcategory within a main category
type SubCategory struct {
	Name     string
	Settings []MergedSetting
}

// CategoryWithSubCategories represents a main category with its subcategories
type CategoryWithSubCategories struct {
	Name          string
	SubCategories []SubCategory
}

// GroupSettingsWithSubCategories groups settings by main category and subcategory
func (s *Settings) GroupSettingsWithSubCategories(modelSettings []*models.Setting, settingType SettingType, category string) []CategoryWithSubCategories {
	mergedSettings := s.Merge(modelSettings, settingType)

	// Filter settings by the specified category
	var filteredSettings []MergedSetting
	for _, setting := range mergedSettings {
		if setting.Category == category {
			filteredSettings = append(filteredSettings, setting)
		}
	}

	// If no settings match the category, return an empty slice
	if len(filteredSettings) == 0 {
		return []CategoryWithSubCategories{}
	}

	// Create a single CategoryWithSubCategories for the specified category
	result := CategoryWithSubCategories{
		Name: category,
		SubCategories: []SubCategory{
			{
				Name:     category,
				Settings: filteredSettings,
			},
		},
	}

	// Sort settings by order
	sort.Slice(result.SubCategories[0].Settings, func(i, j int) bool {
		return result.SubCategories[0].Settings[i].Order < result.SubCategories[0].Settings[j].Order
	})

	return []CategoryWithSubCategories{result}
}

// GetCategorySettings retrieves all settings for a specific main category
func (s *Settings) GetCategorySettings(category string, modelSettings []*models.Setting, settingType SettingType) CategoryWithSubCategories {
	allCategories := s.GroupSettingsWithSubCategories(modelSettings, settingType, category)
	for _, cat := range allCategories {
		if cat.Name == category {
			return cat
		}
	}
	return CategoryWithSubCategories{} // Return empty if not found
}

// The Save function remains commented out as per the original code
/*
// Save persists the updated setting to the database.
func Save(ctx context.Context, db models.SqlxDB, userModel *models.User, accountModel *models.Account, category, key, role, value string) error {
	canUpdate := false
	if accountModel.PrimaryUserID != userModel.ID && role == "admin" {
		canUpdate = true
	} else if role == "user" {
		canUpdate = true
	}

	if canUpdate {
		setting, err := models.SettingByAccountIDUserIDCategoryKey(ctx, db, types.NewNullInt64(accountModel.ID), types.NewNullInt64(userModel.ID), category, key)
		if err != nil {
			fmt.Println("Error looking up setting", err.Error())
			return err
		}

		if setting == nil {
			setting = &models.Setting{
				AccountID: types.NewNullInt64(accountModel.ID),
				UserID:    types.NewNullInt64(userModel.ID),
				Category:  category,
				Key:       key,
				Value:     value,
			}
		} else {
			setting.Value = value
		}

		err = setting.Save(ctx, db)
		if err != nil {
			fmt.Println("Error saving setting", err.Error())
			return err
		}
	}

	return nil
}
*/
