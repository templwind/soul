# TypeScript API Client

This directory contains a TypeScript API client that is automatically generated from your API definitions.

## Nested Namespaces

API functions are organized into nested namespaces based on their path structure to prevent naming collisions and provide a more intuitive organization.

### Path-Based Namespaces

Functions are organized into primary and secondary namespaces based on the API path structure:

- For paths like `/api/blog`, functions are available under `Api.Blog` namespace
- For paths like `/auth/login`, functions are available under `Auth` namespace

### Resource-Based Namespaces

For handlers that define multiple HTTP methods for the same resource, a resource-specific namespace is created:

```typescript
// A handler named "getProfile" with GET and POST methods becomes:
export namespace Profile {
  export function Get(options?: { fetch?: typeof fetch }): Promise<models.Profile> {
    return api.get<models.Profile>(`/api/profile`, undefined, options?.fetch);
  }
  
  export function Post(req: models.Profile, options?: { fetch?: typeof fetch }): Promise<models.Profile> {
    return api.post<models.Profile>(`/api/profile`, req, undefined, options?.fetch);
  }
}
```

This prevents naming collisions when a handler defines multiple methods with the same path.

### Private Namespace

Endpoints that require authentication are automatically placed in a special `Private` namespace, making it easy to identify which API calls require a logged-in user.

### Example Usage

```typescript
import { Api, Auth, Private, Profile } from '../lib/api';

// Public API functions
const blogPosts = await Api.Blog.List(1, 10, '', '', '');
const loginResult = await Auth.Login({ email: 'user@example.com', password: 'password' });

// Resource API functions
const profile = await Profile.Get();
await Profile.Post(updatedProfile);

// Private (authenticated) API functions
const subscription = await Private.Subscription();
```

## Namespace Configuration

You can control the namespace structure using annotations in your API definition:

```
@server(
    namespace: "Api"
    subnamespace: "Blog"
    jwt: "Auth"  // This will place the endpoint in the Private namespace
)
```

For resource-specific namespaces, use naming conventions like:

```
@handler getProfile  // Will create a Profile namespace with Get and Post methods
get /profile returns (Profile)
post /profile (Profile) returns (Profile)
```

## API Structure

The API client is organized as follows:

- `endpoints.ts` - Contains all API function definitions organized by namespace
- `models.ts` - Contains TypeScript interfaces for all request and response types
- `constants.ts` - Contains constants used by the API
- `request.ts` - Contains the base request functions used by the API client
- `index.ts` - Exports all API functions, models, and constants

## Adding Custom API Functions

If you need to add custom API functions that aren't automatically generated, you can create a new file (e.g., `custom.ts`) and import/export it in `index.ts`. 