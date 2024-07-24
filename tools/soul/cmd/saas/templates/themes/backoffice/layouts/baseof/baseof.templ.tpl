package baseof

templ tpl(props *Props) {
    <!DOCTYPE html>
    <html 
    if len(props.LangCode) > 0 {
        lang={props.LangCode}
    }
    if len(props.LTRDir) > 0 {
       dir={props.LTRDir}
    }
    if len(props.BodyClass) > 0 {
        class={props.BodyClass}
    }
    >
        <head>
         if props.Head != nil {
            @props.Head
         }
        </head>
        <body 
            class="h-full overflow-hidden antialiased bg-white"
            hx-boost="true"
           	if props.HxSSE != nil && props.HxSSE.URL != "" {
                hx-ext="sse"
                sse-connect={ props.HxSSE.URL }
            }
            if len(props.XData) > 0 {
                x-data={ props.XData }
            }
            if len(props.XInit) > 0 {
                x-init={ props.XInit }
            }
        >
            <div class="flex flex-col w-full h-full overflow-hidden">
                <div class="flex flex-auto w-full h-full overflow-hidden">
                    if props.RailMenu != nil {
                        @props.RailMenu
                    }
                    <div class="flex flex-col flex-1 overflow-x-hidden">
                        <main
                            class="flex-auto overflow-y-auto bg-slate-100 dark:bg-slate-700"
                            id="content"
                        >
                            if props.Header != nil {
                                @props.Header
                            }
                            if props.Content != nil {
                                @props.Content
                            }
                        </main>
                    </div>
                </div>
                 if props.Footer != nil {
                    @props.Footer
                }
            </div>
            <div sse-swap="toast" class="fixed z-50 bottom-4 right-4"></div>
        </body>
    </html>
}
