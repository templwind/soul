PACKAGES := $(shell go list ./...)
name := $(shell basename ${PWD})

# Docker parameters
EXECUTABLE={{ .AppName }}
NAMESPACE={{ .Namespace }}
DOCKER=docker
DOCKER_BUILD=$(DOCKER) build
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=260264107230
AWS_ECR_REPO=${NAMESPACE}/${EXECUTABLE}
AWS_ECR_TAG=latest
AWS_ECR_URL=$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(AWS_ECR_REPO)
AWS_LOGIN=$(shell aws ecr get-login-password --region $(AWS_REGION))
$(eval COMMIT_HASH := $(shell git rev-parse --short HEAD))
TIMESTAMP ?= $(shell date +"%Y%m%d%H%M%S")
	VERSION ?= $(shell git describe --tags --always || git rev-parse --short HEAD)
LDFLAGS ?= -X 'main.Version=$(VERSION)'

xo_includes=accounts \
user_types \
users \
user_accounts

DSN ?= ./.data.db

all: help

.PHONY: help
help: Makefile
	@echo
	@echo " Application Name: {{ .AppName }}"
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
	
## build: build project
.PHONY: build
build:
	make templ-generate
	go build -ldflags "-X main.Environment=production" -o ./tmp/{{ .AppName }} .

## staticcheck: run staticcheck
.PHONY: staticcheck
staticcheck:
	staticcheck ./...

## xo: generate models from database
.PHONY: xo
xo:
	@mkdir -p ./internal/models
	@xo schema \
		'file:${DSN}??loc=auto' \
		--go-field-tag='json:"{{ envvar ".SQLName" }}" db:"{{ envvar ".SQLName" }}" form:"{{ envvar ".SQLName" }}"' \
		--include=$(shell echo "${xo_includes}" | xargs | sed -e 's/ /\ --include=/g') \
		-o ./internal/models \
		-k field

	@xoclir parsexo -i ./internal/models -o ./internal/models -b {{ .ModuleName }}/internal
	@go mod tidy


## docker-build: build docker image
.PHONY: docker-build
docker-build:
	$(DOCKER_BUILD) --platform=linux/amd64 -t $(AWS_ECR_URL):latest -t $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH) .

## docker-run: run docker image
.PHONY: docker-push
docker-push:
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ECR_URL)
	$(DOCKER) push $(AWS_ECR_URL):latest
	$(DOCKER) push $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH)
	docker rmi $(AWS_ECR_URL):latest
	docker rmi $(AWS_ECR_URL):main-$(TIMESTAMP)-$(COMMIT_HASH)
