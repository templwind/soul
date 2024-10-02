Certainly! Here's a draft for the json_handling.md file, explaining how JSON input and output are handled in Soul CLI:

# JSON Handling in Soul CLI

Soul CLI provides robust support for working with JSON data, both for input (request bodies) and output (responses). This document explains how JSON handling is implemented and used in Soul CLI projects.

## Overview of JSON Handling

Soul CLI automatically generates code to handle JSON serialization and deserialization based on your API definitions. This ensures type-safe and efficient JSON handling in your SaaS application.

## Defining JSON Structures in the API File

To work with JSON data, you first need to define your data structures in the API file. Soul CLI uses these definitions to generate appropriate Go structs and TypeScript interfaces.

Example:

```
type CreateUserRequest {
    Username string `json:"username"`
    Email    string `json:"email"`
    Age      int    `json:"age,optional"`
}

type User {
    ID       int    `json:"id"`
    Username string `json:"username"`
    Email    string `json:"email"`
    Age      int    `json:"age,omitempty"`
}

@server (
    group: users
)
service YourSaaS {
    @handler createUser
    post /users (CreateUserRequest) returns (User)
}
```

## Handling JSON Input

### In Handlers

Soul CLI generates handler code that automatically parses JSON input:

```go
func CreateUserHandler(svcCtx *svc.ServiceContext, path string) echo.HandlerFunc {
    return func(c echo.Context) error {
        var req types.CreateUserRequest
        if err := httpx.Parse(c, &req, path); err != nil {
            return err
        }

        l := users.NewCreateUserLogic(c.Request().Context(), svcCtx)
        resp, err := l.CreateUser(&req)
        if err != nil {
            return err
        }

        return c.JSON(http.StatusOK, resp)
    }
}
```

The `httpx.Parse` function handles JSON deserialization for you.

### In Logic Layer

In your logic layer, you can work with the parsed JSON data as a Go struct:

```go
func (l *CreateUserLogic) CreateUser(req *types.CreateUserRequest) (resp *types.User, err error) {
    // req.Username, req.Email, and req.Age are now available as struct fields
    user, err := l.svcCtx.DB.CreateUser(req.Username, req.Email, req.Age)
    if err != nil {
        return nil, err
    }
    return user, nil
}
```

## Handling JSON Output

Soul CLI automatically handles JSON serialization for your responses:

```go
return c.JSON(http.StatusOK, resp)
```

This line in the handler serializes your response struct to JSON.

## Working with JSON Arrays

Soul CLI supports JSON arrays out of the box. You can define them in your API file like this:

```
type UserList {
    Users []User `json:"users"`
}

@server (
    group: users
)
service YourSaaS {
    @handler listUsers
    get /users returns (UserList)
}
```

## Nested JSON Structures

You can define nested JSON structures in your API file:

```
type Address {
    Street  string `json:"street"`
    City    string `json:"city"`
    Country string `json:"country"`
}

type UserWithAddress {
    ID      int     `json:"id"`
    Username string  `json:"username"`
    Address Address `json:"address"`
}
```

Soul CLI will generate appropriate nested structs in Go and nested interfaces in TypeScript.

## JSON Tags

Soul CLI respects JSON tags in your struct definitions:

- `json:"fieldname"`: Specifies the JSON field name.
- `json:",omitempty"`: Omits the field from JSON output if it's empty or zero-valued.
- `json:"-"`: Excludes the field from JSON serialization/deserialization.

## Handling Optional Fields

For optional fields, you can use pointers in your Go structs:

```go
type CreateUserRequest struct {
    Username string  `json:"username"`
    Email    string  `json:"email"`
    Age      *int    `json:"age,omitempty"`
}
```

This allows `Age` to be omitted from the JSON input, and it will be `nil` if not provided.

## Custom JSON Marshaling/Unmarshaling

If you need custom JSON marshaling or unmarshaling, you can implement the `json.Marshaler` and `json.Unmarshaler` interfaces for your types:

```go
func (u *User) MarshalJSON() ([]byte, error) {
    // Custom marshaling logic
}

func (u *User) UnmarshalJSON(data []byte) error {
    // Custom unmarshaling logic
}
```

## Best Practices

1. **Use Appropriate Types**: Choose the right Go types for your JSON fields (e.g., `int64` for large numbers, `float64` for decimals).
2. **Validate Input**: Always validate JSON input in your logic layer before using it.
3. **Handle Errors Gracefully**: Provide meaningful error messages for JSON parsing errors.
4. **Use Pointers for Optional Fields**: This clearly distinguishes between "field not provided" and "field provided with zero value".
5. **Document Your JSON Structures**: Clearly document the expected format of your JSON inputs and outputs.

## Troubleshooting

If you're having issues with JSON handling:

1. Ensure that your struct field names match the JSON field names (or use appropriate JSON tags).
2. Check that the types in your structs match the expected JSON types.
3. For optional fields, consider using pointers or the `omitempty` tag.
4. Use a JSON validator to ensure your JSON is well-formed.

## Conclusion

JSON handling in Soul CLI is designed to be seamless and type-safe. By leveraging the automatic code generation and built-in parsing functions, you can focus on your business logic rather than the intricacies of JSON serialization and deserialization. This approach helps create robust and maintainable SaaS applications with efficient JSON processing.
