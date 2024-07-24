Sure, here's the entire content in a single, copyable markdown code block:

# API Definition File Documentation

This document outlines the syntax and structure for defining APIs in our custom definition format.

## File Structure

The API definition file consists of several main sections:

1. File header
2. Type definitions
3. Server definitions
4. Service definitions

### 1. File Header

The file starts with a header that includes metadata about the API:

```golang
    syntax = "v1"
    info (
    title:   "API Title"
    desc:    "API Description"
    author:  "Author Name"
    date:    "YYYY-MM-DD"
    version: "v1"
)
```

### 2. Type Definitions

Types are defined using a struct-like syntax:

```golang
type TypeName {
    FieldName FieldType tag:"value"
}
```

Example:

```golang
type LoginRequest {
    Email    string form:"email" validate:"required,email"
    Password string form:"password" validate:"required,min=6,max=32"
}
```

### 3. Server Definitions

Server blocks define global settings for a group of endpoints:

```golang
@server (
    group:      groupName
    prefix:     /prefix
    theme:      themeName
    languages:  lang1,lang2
    jwt:        AuthName
    middleware: Middleware1,Middleware2
    assetGroup: assetGroupName
)
```

### 4. Service Definitions

Services are defined within a server block and contain individual endpoint definitions:

```golang
service ServiceName {
    @handler handlerName
    @page(
     title: "Page Title"
    )
    method /path
    method /path/:param (InputType) returns (OutputType)
    method /path returns partial
}
```

## Endpoint Definition Syntax

Endpoints are defined using the following syntax:

```golang
method /path/:param (InputType) returns (OutputType)
```

- `method`: HTTP method (get, post, put, delete)
- `/path`: URL path, can include path parameters (`:param`)
- `(InputType)`: Optional input type
- `returns (OutputType)`: Optional return type
- `returns partial`: Indicates the endpoint returns partial content

Examples:

```golang
get /home
post /update (UpdateReq)
get /list returns ([]ListItem)
put /account/info (AccountInfoForm) returns partial
```

### WebSocket Endpoints

WebSocket endpoints are defined with the `socket` keyword:

```golang
get socket /ws (
client:action >> (OutputType)
server:action << (InputType)
)
```

## Annotations

Annotations provide additional metadata for handlers and pages:

```golang
@handler handlerName
@page(
title: "Page Title"
prerender: true
)
```

## Complete Example

```golang
type ContactReq {
    Email string `form:"Email"`
}

@server (
    group:      app
    prefix:     /app
    theme:      backoffice
    languages:  en,es
    jwt:        Auth
    middleware: Locale,AuthGuard
    assetGroup: app
)

service TestSite {
    @handler home
    @page(
        title: Home
    )
    get /

    @handler about
    @page(
        title: About
    )
    get /about

    @handler contact
    @page(
        title: Contact
    )
    get /contact
    post /contact (ContactReq) returns partial

    @handler liveChat
    @page(
        title: liveChat
    )
    get socket /chat (
        client:request >> (ListItem)
        server:messages << ([]Messages)
    )
}
```
