# Soul New Project Generator - Feature Requirements

This document outlines the functional and non-functional requirements for the new `soul new project` generator.

## 1. Core Goal

To provide a command-line tool (`soul new project`) that generates a robust, flexible, and LLM-friendly Go backend project structure based on a declarative `.api` specification. The generated project should serve as a foundation for various web applications, particularly SaaS products.

## 2. Functional Requirements

### 2.1. Command Structure

- The generator shall be invoked via `soul new project <project_name> [flags]`.
- It must accept flags to specify the input `.api` specification file (`--api`) and the output directory (`--dir`).

### 2.2. Backend Generation

- **Hybrid Serving:** The generated Go backend must support serving:
  - JSON APIs.
  - Static files (including SPA support).
  - Dynamic HTML views rendered using integrated `templ` components.
- **Configuration:** All serving modes (API routes, static file rules, dynamic view routes) shall be configured declaratively within the `.api` specification file.
- **Echo Framework:** The backend shall use `github.com/labstack/echo/v4` as the underlying web framework.
- **Templ Integration:** The backend shall use `github.com/a-h/templ` for dynamic HTML view rendering, integrated via the `soul.Render` function or similar mechanism.

### 2.3. Database Integration

- **Schema Definition:** The source of truth for database entity structures shall be manually defined Go structs located in a standard directory (e.g., `models/`).
- **Data Access Layer:** The generator shall integrate `github.com/sqlc-dev/sqlc`.
  - Database queries (SELECT, INSERT, UPDATE, DELETE) shall be defined in standard `.sql` files.
  - `sqlc` shall be used to generate type-safe Go functions for executing these queries.
  - The generator shall include running `sqlc generate` as part of the project setup.
- **Core Components:** The generator shall provide template files for:
  - Core Go model structs (e.g., users, teams).
  - Core `.sql` files containing schema definitions (e.g., `CREATE TABLE`) and common queries for the core models.
  - A pre-configured `sqlc.yaml` file.

### 2.4. API Specification (`.api`)

- The `.api` file format shall remain the central definition for:
  - Data types used in API requests/responses.
  - API route definitions (path, method, request/response types, middleware).
  - Static file serving rules (e.g., using `get static`, `get static-embed` syntax).
  - Routes intended for dynamic HTML rendering (linking implicitly or explicitly to `templ` components).
  - Server group configurations (prefix, middleware, JWT settings, theme/template association).

### 2.5. API Client Generation

- The generator must produce a **TypeScript API client library** based on the API routes and types defined in the `.api` specification.
- This client library should include:
  - TypeScript interfaces/types corresponding to the `.api` types.
  - Functions for making type-safe calls to each API endpoint.
  - A configurable base client (e.g., using `fetch` or `axios`).
- The generated client library shall be placed in a standard output directory (e.g., `clients/ts/`).

### 2.6. Authentication

- The generated backend must support JWT-based authentication.
- It must handle JWTs passed via:
  - Secure, HttpOnly cookies (for same-domain scenarios).
  - `Authorization: Bearer <token>` headers (for cross-domain/external clients).
- Generated login endpoints should facilitate both methods.
- Generated JWT middleware must be configurable via the `.api` spec.
- Appropriate CORS middleware configuration must be included and easily adjustable.

### 2.7. Frontend Agnosticism

- The generator **shall not** scaffold or include a specific frontend framework (e.g., SvelteKit, React). It only provides the backend and the API client libraries.

## 3. Non-Functional Requirements

### 3.1. LLM Friendliness

- The generated code structure, clear separation of concerns (models, SQL, API spec, generated code), and reliance on declarative definitions should make the project easy for Large Language Models to understand, modify, and extend safely and rapidly.

### 3.2. Maintainability

- The generated code should follow standard Go practices and be well-organized.

### 3.3. Extensibility

- Users should be able to easily add new models, SQL queries, `.api` definitions, and `templ` components, regenerating code as needed.

### 3.4. Documentation

- Clear documentation must be provided for the `soul new project` command, the expected workflow, and the structure of the generated project. The LLM guide (`docs/llm_guide.md`) must be updated.

## 4. Out of Scope (Initially)

- Generation of API client libraries for languages other than TypeScript.
- Scaffolding specific frontend framework projects.
- Advanced database migration tooling integration (beyond providing initial `CREATE TABLE` statements).
