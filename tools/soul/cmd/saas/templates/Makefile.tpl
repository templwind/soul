# Load environment variables from .env file
ifneq (,$(wildcard .env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif

# Dynamic variables
APP_NAME := $(shell cd {{.serviceName}} && grep -lR "func main()" *.go | awk -F/ '{print $$NF}' | sed 's/\.go//')
PACKAGES := $(shell cd {{.serviceName}} && go list ./...)
NAME := $(shell basename ${PWD})
{{ if .externalDockerNetwork -}}
EXTERNAL_DOCKER_NETWORK={{ .externalDockerNetwork }}
{{- end }}

# Docker parameters
EXECUTABLE={{ .serviceName }}

all: help

.PHONY: help
help: Makefile
	@echo
	@echo " Application Name: $(APP_NAME)"
	@echo
	@echo " Choose a make command to run"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

## gen: Generate the website from the ast code
.PHONY: gen
gen:
	{{ if .isService -}}
	{{- if .externalDockerNetwork -}}
	soul saas -a ${EXECUTABLE}.api -d . -m true -s true -n ${EXTERNAL_DOCKER_NETWORK}
	{{- else }}
	soul saas -a ${EXECUTABLE}.api -d . -m true -s true
	{{- end -}}
	{{- else -}}
	soul saas -a ${EXECUTABLE}.api -d .
	{{- end -}}

