Certainly! Here's a draft for the typescript_clients.md file, explaining how TypeScript clients are generated and used in Soul CLI:

# TypeScript Clients in Soul CLI

Soul CLI automatically generates TypeScript clients for your API endpoints, providing type-safe and easy-to-use interfaces for frontend development. This document explains how TypeScript clients are generated, structured, and used in Soul CLI projects.

## Overview of TypeScript Client Generation

Soul CLI analyzes your API definitions and automatically generates TypeScript clients that mirror your backend structure. This ensures type safety and provides autocompletion in your frontend code.

## Generation Process

TypeScript clients are generated automatically when you run:

```
make gen
```

This command analyzes your API definitions and creates or updates the following files:

- `app/src/api/models.ts`: Contains TypeScript interfaces for all your API models.
- `app/src/api/endpoints.ts`: Contains functions for all your API endpoints.
- `app/src/api/index.ts`: Exports all models and endpoints for easy importing.

## Structure of Generated Files

### models.ts

This file contains TypeScript interfaces that correspond to your API models. For example:

```typescript
export interface User {
  id: number;
  username: string;
  email: string;
  createdAt: string;
}

export interface CreateUserRequest {
  username: string;
  email: string;
  password: string;
}
```

### endpoints.ts

This file contains functions for each of your API endpoints. For example:

```typescript
import * as models from "./models";

export function createUser(
  req: models.CreateUserRequest
): Promise<models.User> {
  return api.post<models.User>("/api/users", req);
}

export function getUser(id: number): Promise<models.User> {
  return api.get<models.User>(`/api/users/${id}`);
}
```

### index.ts

This file re-exports all models and endpoints for convenient importing:

```typescript
export * from "./models";
export * as api from "./endpoints";
```

## Using TypeScript Clients in Your Frontend

To use the generated TypeScript clients in your frontend code:

1. Import the necessary functions and models:

```typescript
import { api, User, CreateUserRequest } from "@/api";
```

2. Use the imported functions with full type safety:

```typescript
async function createNewUser() {
  const newUser: CreateUserRequest = {
    username: "johndoe",
    email: "john@example.com",
    password: "securepassword",
  };

  try {
    const user: User = await api.createUser(newUser);
    console.log("User created:", user);
  } catch (error) {
    console.error("Error creating user:", error);
  }
}
```

## Benefits of Using Generated TypeScript Clients

1. **Type Safety**: Catch errors at compile-time rather than runtime.
2. **Autocompletion**: Get intelligent code completion in your IDE.
3. **Refactoring Support**: Easily refactor your codebase with confidence.
4. **Documentation**: The TypeScript interfaces serve as living documentation of your API structure.

## Best Practices

1. **Keep API Definitions Updated**: Always keep your API definitions up-to-date to ensure the generated clients are accurate.
2. **Use Generated Types**: Always use the generated types instead of creating your own.
3. **Don't Modify Generated Files**: Avoid modifying the generated files directly. If you need to extend functionality, create wrapper functions.
4. **Regenerate After API Changes**: Always regenerate the TypeScript clients after making changes to your API.

## Handling API Versioning

If you're using API versioning, Soul CLI generates separate client files for each version. For example:

- `app/src/api/v1/models.ts`
- `app/src/api/v1/endpoints.ts`
- `app/src/api/v2/models.ts`
- `app/src/api/v2/endpoints.ts`

You can then import from the specific version you need:

```typescript
import { api as apiV1 } from "@/api/v1";
import { api as apiV2 } from "@/api/v2";
```

## WebSocket Support

For WebSocket endpoints, Soul CLI generates specialized client functions. For example:

```typescript
export function connectWebSocket(): WebSocket {
  return new WebSocket("ws://localhost:8080/ws");
}

export function sendChatMessage(
  ws: WebSocket,
  message: models.ChatMessage
): void {
  ws.send(JSON.stringify({ topic: "chat", payload: message }));
}
```

## Conclusion

The automatically generated TypeScript clients in Soul CLI provide a powerful, type-safe way to interact with your backend API from your frontend code. By leveraging these generated clients, you can significantly reduce the likelihood of runtime errors and improve the overall development experience in your SaaS project.
