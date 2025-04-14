# Load environment variables from .env file
ifneq (,$(wildcard .env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif

# Dynamic variables
APP_NAME := $(shell cd backend && grep -lR "func main()" *.go | awk -F/ '{print $$NF}' | sed 's/\.go//')
PACKAGES := $(shell cd backend && go list ./...)
NAME := $(shell basename ${PWD})


# Docker parameters
EXECUTABLE=backend

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
	soul new -a ./ast/main.api -d .  \
      --client default:./frontend/src/lib/api \
      --client admin:./admin/src/lib/api