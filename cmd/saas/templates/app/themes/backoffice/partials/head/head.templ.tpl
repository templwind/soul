package head

import "fmt"

templ tpl(props *Props) {
	<meta charset="utf-8"/>
	<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
	<title>
		if props.IsHome {
			{ props.SiteTitle }
		} else {
			{ fmt.Sprintf("%s | %s", props.Title, props.SiteTitle) }
		}
	</title>
	if props.Environment == "development" {
		for _, cssPath := range props.CSS {
			<link rel="stylesheet" href={ cssPath }/>
		}
		for _, jsPath := range props.JS {
			<script defer src={ jsPath }></script>
		}
	} else {
		for _, cache := range props.CssCache {
			<link rel="stylesheet" href={ cache.MinifiedPermalink } integrity={ cache.Integrity } crossorigin="anonymous"/>
		}
		for _, cache := range props.JSCache {
			<script defer src={ cache.MinifiedPermalink } integrity={ cache.Integrity } crossorigin="anonymous"></script>
		}
	}
	// @props.JS
}
