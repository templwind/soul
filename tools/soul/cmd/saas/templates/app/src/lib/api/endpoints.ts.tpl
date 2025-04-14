// Code generated by soul. DO NOT EDIT.
//
// API functions are organized into nested namespaces:
// - Primary namespaces (Api, Auth, etc.) represent the top-level path segment
// - Secondary namespaces (Blog, User, etc.) represent the second path segment
// - Resource namespaces (Profile, User, etc.) group methods for the same resource
// - The Private namespace contains all endpoints that require authentication
//
// For example, a handler named "getProfile" with GET and POST methods will be organized as:
// 
// export namespace Profile {
//   export function Get(...) {...}
//   export function Post(...) {...}
// }
//
// This prevents naming collisions and provides better organization of API functions.

import client from "./api-client";
import * as models from "./models";

{{ .Endpoints -}}
