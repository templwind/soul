# Installing Soul CLI

Soul CLI is a Go-based application that supports all major platforms. It's also Docker and Kubernetes ready, making it versatile for various development and deployment environments.

## System Requirements

- Any operating system that supports Go
- Homebrew (for macOS and Linux users)

## Installation Steps

### Using Homebrew (Recommended for macOS and Linux)

1. Tap the Soul CLI repository:

   ```
   brew tap templwind/soul
   ```

2. Install Soul CLI:
   ```
   brew install soul
   ```

### For Other Platforms

As Soul CLI is a Go-based application, it can be built and run on any platform that supports Go. Detailed instructions for manual installation will be provided soon.

## Docker and Kubernetes

Soul CLI is Docker and Kubernetes ready. Detailed instructions for using Soul CLI with Docker and Kubernetes will be provided in the advanced usage guide.

## Verifying the Installation

After installation, you can verify that Soul CLI is correctly installed by running:

```
soul version
```

You should see output similar to:

```
soul version v0.0.3
```

## Exploring Soul CLI Commands

To see all available commands, run:

```
soul -h
```

This will display a list of commands including:

- `echo`: Generate a new site using echo
- `saas`: Generate a new saas site
- `install` (or `i`): Install components, pages, or modules
- `update`: Check for and install the latest version of the CLI tool
- And more...

## Next Steps

Now that you have Soul CLI installed, you're ready to start building your SaaS product. Head over to the [Getting Started](./getting_started.md) guide to create your first Soul CLI project.
