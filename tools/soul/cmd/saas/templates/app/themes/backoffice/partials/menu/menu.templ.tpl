package menu

import (
    "{{ .serviceName }}/internal/config"
)

templ tpl(props *Props) {
    if _, ok := props.Menus[props.MenuKey]; ok && len(props.Menus[props.MenuKey]) > 0 {
        if props.MenuKey == "rail" {
			@appRail(props)
		} else {
		<web-menu>
			<ul 
			if len(props.MenuID) > 0 {
				id={props.MenuID}
			}
			>
				@walkMenu(props.Menus[props.MenuKey])
			</ul>
		</web-menu>
        }
    }
}

templ walkMenu(entries []config.MenuEntry) {
    for _, entry := range entries {
        <li>
            <a href={ templ.SafeURL(entry.URL) }>
                { entry.Title }
            </a>
            if len(entry.Children) > 0 {
                <ul>
                    @walkMenu(entry.Children)
                </ul>
            }
        </li>
    }
}

