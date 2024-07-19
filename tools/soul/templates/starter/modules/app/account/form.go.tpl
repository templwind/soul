package account

import (
	"context"
	"fmt"
	"io"
	"strings"

	"{{ .ModuleName }}/internal/config"
	"{{ .ModuleName }}/internal/models"
	"{{ .ModuleName }}/internal/types"

	"github.com/a-h/templ"
)

func getCountryOptions(props *Props) templ.Component {
	return templ.ComponentFunc(func(ctx context.Context, w io.Writer) error {
		var options string
		var hasSelection bool
		for code, name := range props.CountryCodes {
			options += fmt.Sprintf({{ `<option value="%s"` | ticked }}, code)
			if !hasSelection {
				if account.Country.Valid && strings.EqualFold(types.NewStringFromNull(account.Country), code) {
					options += " selected"
					hasSelection = true
				}
			}
			options += fmt.Sprintf({{ ">%s</option>" | ticked }}, name)
		}

		_, err := io.WriteString(w, options)
		return err
	})
}
