package sitelayout

import (
	"github.com/templwind/templwind/htmx"
)

templ tpl(props *Props) {
	if !htmx.IsHtmxRequest(props.Echo.Request()) || htmx.IsHtmxBoosted(props.Echo.Request()) {
		<!DOCTYPE html>
		<html lang="en">
			<head>
				<meta charset="utf-8"/>
				<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
				<meta http-equiv="X-UA-Compatible" content="ie=edge"/>
				<title>{{ .ModuleName | title }} {props.PageTitle}</title>
				<meta name="description" content=""/>
				<meta name="keywords" content=""/>
				<meta name="author" content=""/>
				<link rel="stylesheet" href="/assets/css/styles.css"/>
    			<script defer src="/assets/js/main.js"></script>
			</head>
			<body>
				<div class="flex flex-col min-h-screen">
					<div class="flex flex-col flex-1 sm:flex-row">
						<main class="flex-1 p-4 bg-indigo-100">
							{ children... }
						</main>
					</div>
				</div>
			</body>
		</html>
	} else {
		{ children... }
	}
}