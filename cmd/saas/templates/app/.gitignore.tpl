##############################
# go gitignore 
# https://github.com/github/gitignore/blob/main/Go.gitignore
##############################

# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with `go test -c`
*.test

# Output of the go coverage tool, specifically when used with LiteIDE
*.out

# Dependency directories (remove the comment below to include it)
# vendor/

# Go workspace file
go.work
go.work.sum

# env file
.env


##############################
# pnpm gitignore 
# https://github.com/pnpm/pnpm/blob/main/.gitignore
##############################
# Logs
logs
*.log
npm-debug.log*

# Dependency directory
**/node_modules/**
_node_modules
.pnp.cjs

# Database files for local development
.db/

# Coverage directory used by tools like istanbul
coverage

.tmp
_docpress
.DS_Store

lib
dist
tsconfig.tsbuildinfo

# Visual Studio Code configs
.vscode/

# JetBrains IDEs
.idea/

# pnpm uses npm for publishing a new version with
# dependencies bundled but the npm lockfile is not needed
# because pnpm use pnpm for installation
package-lock.json

__package_previews__
.store

privatePackages/store

## Verdaccio storage
storage

yarn.lock

RELEASE.md

.jest-cache
.verdaccio-cache
.turbo

## custom modules-dir fixture
__fixtures__/custom-modules-dir/**/fake_modules/
__fixtures__/custom-modules-dir/cache/
__fixtures__/custom-modules-dir/patches/

