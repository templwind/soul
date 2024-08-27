# HTML Rendering in Soul CLI

Soul CLI uses the Templ library for efficient and type-safe HTML rendering. This document explains how Templ is integrated into Soul CLI projects and best practices for working with it.

## Templ Integration in Soul CLI

Soul CLI tightly integrates Templ into its project structure, providing a seamless way to create dynamic HTML content. Here's how it works:

1. **File Structure**: Templ files are typically located in the `internal/logic` directory, alongside their corresponding Go files.

2. **Component Creation**: Each Templ file defines a view function that represents an HTML component.

3. **Props and Logic**: Each component has an associated `props.go` file that defines the component's properties and provides functions for creating and manipulating the component.

4. **Handler Integration**: The handlers, located in the `internal/handler` directory, use the logic files to render the appropriate Templ components.

## Important Note on Auto-Generated Files

It's crucial to understand that certain files in a Soul CLI project are auto-generated and will be overwritten if modified directly. These include:

- All files in the `internal/handler` directory, including `routes.go` and individual handler files (e.g., `homehandler.go`).
- The `internal/svc/servicecontext.go` file.

These files are generated based on your API definitions and should not be edited manually. If you need to modify the behavior defined in these files, you should update your API definition and regenerate the project structure.

## Key Features of Templ in Soul CLI

1. **Type Safety**: Templ provides compile-time checking of your templates, catching errors early in the development process.

2. **Component-Based**: Templ encourages a component-based architecture, making it easy to create reusable UI elements.

3. **Go Integration**: Templ templates are compiled to Go code, allowing for seamless integration with your Go application logic.

4. **Performance**: Templ is designed for high performance, with minimal runtime overhead.

## Best Practices

1. **Separate Logic and View**: Keep your business logic in the `.go` files and your view logic in the `.templ` files within the `internal/logic` directory.

2. **Use Props**: Utilize the Props struct and associated functions to pass data to your components in a structured way.

3. **Leverage Layouts**: Use layout components to provide a consistent structure across pages.

4. **API-First Development**: Make changes to your API definition file first, then use Soul CLI to regenerate the handlers and routes.

5. **Custom Logic in Logic Files**: Implement your custom business logic in the logic files (e.g., `home.go` in the `internal/logic` directory). These files are not overwritten by the generator.

## Example Workflow

1. Define your routes and handlers in your API file.

2. Generate or regenerate your project structure using Soul CLI.

3. Implement your component in a `.templ` file in the `internal/logic` directory:

   ```go
   // home.templ
   package home

   templ homeView(props *Props) {
       <div>
           <h1>{ props.PageTitle }</h1>
       </div>
   }
   ```

4. Create the associated props and functions in `props.go` in the same directory:

   ```go
   // props.go
   package home

   type Props struct {
       PageTitle string
   }

   func New(opts ...soul.OptFunc[Props]) templ.Component {
       return soul.New(defaultProps, homeView, opts...)
   }

   func WithTitle(title string) soul.OptFunc[Props] {
     return func(p *Props) {
       p.PageTitle = title
     }
   }
   ```

5. Implement your custom logic in the corresponding `.go` file:

   ```go
   // home.go
   package home

   func (l *HomeLogic) HomeGet(c echo.Context, baseProps *[]soul.OptFunc[baseof.Props]) (templ.Component, error) {
       // Your custom logic here
       return New(
           WithConfig(l.svcCtx.Config),
           WithRequest(c.Request()),
           WithTitle("Home"),
       ), nil
   }
   ```

By following these practices and understanding the structure, you can efficiently create dynamic, type-safe HTML content in your Soul CLI projects while respecting the auto-generated nature of certain files.
