# Load environment variables from .env file
ifneq (,$(wildcard .env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif

# Dynamic variables
APP_NAME := $(shell grep -lR "func main()" *.go | awk -F/ '{print $$NF}' | sed 's/\.go//')
PACKAGES := $(shell go list ./...)
NAME := $(shell basename ${PWD})
COMMIT_HASH := $(shell git rev-parse --short HEAD)
TIMESTAMP ?= $(shell date +"%Y%m%d%H%M%S")
VERSION ?= $(shell git describe --tags --always || git rev-parse --short HEAD)
LDFLAGS ?= -X 'main.Version=$(VERSION)'

# Docker parameters
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012
EXECUTABLE={{.serviceName}}
NAMESPACE={{.serviceName}}
DOCKER=docker
DOCKER_BUILD=$(DOCKER) build
AWS_ECR_REPO=${NAMESPACE}/${EXECUTABLE}
AWS_ECR_TAG=latest
AWS_ECR_URL=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(AWS_ECR_REPO)
AWS_LOGIN=$(shell aws ecr get-login-password --region $(AWS_REGION))
DSN ?= $(shell echo $(DSN) | sed 's|sqlite://||')

# XO includes (parsed from .env)
XO_INCLUDES := $(shell echo "${XO_INCLUDES}" | xargs | sed -e 's/ /\ --include=/g')

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

## vet: vet code
.PHONY: vet
vet:
	go vet $(PACKAGES)

## test: run unit tests
.PHONY: test
test:
	go test -race -cover $(PACKAGES)

## templ: generate new template
.PHONY: templ
templ: 
	templ generate

## templ-watch: watch templ files and format them
.PHONY: templ-watch
templ-watch: 
	templ generate --watch

## templ-fmt: auto-formats templ files
.PHONY: templ-fmt
templ-fmt: 
	templ fmt
	
## pnpm-build: build frontend
.PHONY: pnpm-build
pnpm-build:
	pnpm build

## build: build project
.PHONY: build
build:
	make templ
	go build -ldflags "-X main.Environment=production" -o ./tmp/$(APP_NAME) .

## staticcheck: run staticcheck
.PHONY: staticcheck
staticcheck:
	staticcheck ./...

## gen: Generate the website from the ast code
.PHONY: gen
gen:
	soul saas -a ${EXECUTABLE}.api -d .

## xo: generate models from database
.PHONY: xo
xo:
	@mkdir -p ./internal/models
	@xo schema \
		'file:${DSN}??loc=auto' \
		--go-field-tag='json:"{{ "{{" }} .SQLName {{ "}}" }}" db:"{{ "{{" }} .SQLName {{ "}}" }}" form:"{{ "{{" }} .SQLName {{ "}}" }}"' \
		--include=$(XO_INCLUDES) \
		-o ./internal/models \
		-k field

	@soul parsexo -i ./internal/models -o ./internal/models -b {{.serviceName}}/internal
	@go mod tidy

## backup-db: Backup the SQLite database
.PHONY: backup-db
backup-db:
	docker run --rm --volume sqlite_data:/data alpine \
	/bin/sh -c "cd /data && tar cvzf /data/backup-$(shell date +'%Y%m%d%H%M%S').tar.gz data.db"

## restore-db: Restore the SQLite database from a backup file
.PHONY: restore-db
restore-db:
	@echo "Restoring database from backup file $(BACKUP_FILE)"
	docker run --rm --volume sqlite_data:/data alpine \
	/bin/sh -c "cd /data && tar xzvf /data/$(BACKUP_FILE)"

.PHONY: docker-build
docker-build:
	$(DOCKER_BUILD) --platform=linux/amd64 -t $(AWS_ECR_URL):latest -t $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH) .

.PHONY: docker-push
docker-push:
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ECR_URL)
	$(DOCKER) push $(AWS_ECR_URL):latest
	$(DOCKER) push $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH)
	docker rmi $(AWS_ECR_URL):latest
	docker rmi $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH)
