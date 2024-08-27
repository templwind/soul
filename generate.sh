#!/bin/bash

# Define the base directory
DOCS_DIR="./docs"

# Create the main documentation directory
mkdir -p "$DOCS_DIR"

# Create the top-level markdown files
touch "$DOCS_DIR/introduction.md"
touch "$DOCS_DIR/installation.md"
touch "$DOCS_DIR/getting_started.md"
touch "$DOCS_DIR/troubleshooting.md"
touch "$DOCS_DIR/contributing.md"
touch "$DOCS_DIR/license.md"

# Create the features directory and files
mkdir -p "$DOCS_DIR/features"
touch "$DOCS_DIR/features/html_rendering.md"
touch "$DOCS_DIR/features/json_handling.md"
touch "$DOCS_DIR/features/form_binding.md"
touch "$DOCS_DIR/features/path_binding.md"
touch "$DOCS_DIR/features/websockets.md"
touch "$DOCS_DIR/features/typescript_clients.md"
touch "$DOCS_DIR/features/web_components.md"

# Create the advanced topics directory and files
mkdir -p "$DOCS_DIR/advanced_topics"
touch "$DOCS_DIR/advanced_topics/middleware.md"
touch "$DOCS_DIR/advanced_topics/templating.md"
touch "$DOCS_DIR/advanced_topics/themes_and_assets.md"

# Create the examples directory and files
mkdir -p "$DOCS_DIR/examples"
touch "$DOCS_DIR/examples/prelaunch_site.md"
touch "$DOCS_DIR/examples/lead_magnets.md"
touch "$DOCS_DIR/examples/saas_dashboard.md"

echo "Documentation structure generated in $DOCS_DIR"
