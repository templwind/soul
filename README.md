# Soul CLI Documentation

Welcome to the Soul CLI documentation. This guide will help you understand and use Soul CLI to streamline your SaaS development process.

## Acknowledgment

Soul CLI is heavily influenced by [go-zero](https://github.com/zeromicro/go-zero) in concept and structure. However, we've taken the core ideas beyond microservice architecture to create a unique tool tailored for SaaS development. While inspired by go-zero, Soul CLI has its own distinct codebase and features.

## Table of Contents

### Introduction and Setup

- [Introduction](./docs/introduction.md)
- [Installation](./docs/installation.md)
- [Getting Started](./docs/getting_started.md)

### Features

- [HTML Rendering](./docs/features/html_rendering.md)
- [Form Binding](./docs/features/form_binding.md)
- [JSON Handling](./docs/features/json_handling.md)
- [Path Binding](./docs/features/path_binding.md)
- [WebSockets](./docs/features/websockets.md)
- [TypeScript Clients](./docs/features/typescript_clients.md)
- [Web Components](./docs/features/web_components.md)

### Advanced Topics

- [Middleware](./docs/advanced_topics/middleware.md)
- [Templating](./docs/advanced_topics/templating.md)
- [Themes and Assets](./docs/advanced_topics/themes_and_assets.md)

### Examples

- [Prelaunch Site](./docs/examples/prelaunch_site.md)
- [Lead Magnets](./docs/examples/lead_magnets.md)
- [SaaS Dashboard](./docs/examples/saas_dashboard.md)

### Support and Contribution

- [Troubleshooting](./docs/troubleshooting.md)
- [Contributing](./docs/contributing.md)

## Quick Start

To create a new SaaS project with Soul CLI, use the following command:

```bash
soul saas -a yourfile.api -d .
```

For more detailed instructions, please refer to our [Getting Started](./docs/getting_started.md) guide.

## Key Differences from go-zero

While Soul CLI draws inspiration from go-zero, it differs in several key areas:

1. **Focus on SaaS**: Soul CLI is specifically designed for SaaS development, offering features and templates tailored to common SaaS use cases.

2. **Extended Architecture**: We've expanded beyond microservices to support various architectural patterns common in SaaS applications.

3. **Integrated Frontend Tools**: Soul CLI includes built-in support for TypeScript clients and web components, facilitating full-stack development.

4. **SaaS-specific Features**: Our CLI offers tools for common SaaS requirements like user management, subscription handling, and multi-tenancy.

5. **Customized Templating**: We've developed a unique templating system that caters to SaaS-specific needs and rapid prototyping.

## Support

If you encounter any issues or have questions, please check our [Troubleshooting](./docs/troubleshooting.md) guide. If you can't find the answer there, feel free to open an issue in our GitHub repository.

## Contributing

We welcome contributions to Soul CLI! Please see our [Contributing](./docs/contributing.md) guide for more information on how to get involved.
