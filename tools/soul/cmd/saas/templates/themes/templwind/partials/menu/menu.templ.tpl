package menu

import "{{ .serviceName }}/internal/config"

templ tpl(props *Props) {
    if len(props.MenuEntries) > 0 {
        <web-menu id={props.MenuID}>
            <ul>
                @walkMenu(props.MenuEntries)
            </ul>
        </web-menu>
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
