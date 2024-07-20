package {{.PkgName}}

import (
	"github.com/templwind/templwindhtmx"
)

templ layout(props *Props) {
	if !htmx.IsHtmxRequest(props.Request) || htmx.IsHtmxBoosted(props.Request) {
		<!DOCTYPE html>
		<html lang="en" class="h-full">
			<head>
				<meta charset="utf-8"/>
				<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
				<meta http-equiv="X-UA-Compatible" content="ie=edge"/>
				<title>{props.PageTitle}</title>
				<meta name="description" content=""/>
				<meta name="keywords" content=""/>
				<meta name="author" content=""/>
				<link rel="icon" href="/assets/favicon.svg" type="image/svg+xml"/>
				<link rel="stylesheet" href="/assets/css/styles.css"/>
    			<script defer src="/assets/js/main.js"></script>
			</head>
			<body
				class="h-full antialiased light"
				hx-boost="true"
			>
				<div class="flex flex-col w-full h-full overflow-hidden">
					<div class="flex flex-auto w-full h-full overflow-hidden">
						<div class="flex flex-col flex-1 overflow-x-hidden">
							<main
								class="flex-auto overflow-y-auto bg-slate-100 dark:bg-slate-700"
								id="content"
							>
								{ children... }
							</main>
						</div>
					</div>
				</div>
			</body>
		</html>
	} else {
		{ children... }
	}
}
