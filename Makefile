-include .env

LOCALSTACK_PORT ?= 4566
LOCALSTACK_ENDPOINT ?= http://localhost:$(LOCALSTACK_PORT)

AWS_ENDPOINT_URL ?= $(LOCALSTACK_ENDPOINT)
AWS_ACCESS_KEY_ID ?= test
AWS_SECRET_ACCESS_KEY ?= test
AWS_DEFAULT_REGION ?= us-east-1
export AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

.PHONY: help up down logs health test fmt bootstrap nuke

help: ## List available targets
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN { FS = ":.*## " } { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }'

up: ## Start LocalStack and wait until it is healthy
	docker compose up -d --wait

down: ## Stop LocalStack, keep emulated state on disk
	docker compose down

logs: ## Follow LocalStack logs
	docker compose logs -f localstack

health: ## Print the LocalStack health payload
	@curl -fsS $(LOCALSTACK_ENDPOINT)/_localstack/health | jq .

test: ## Run application unit tests
	python3 -m unittest discover app/api

fmt: ## Format Terraform files
	terraform fmt -recursive terraform

bootstrap: ## Create the S3 bucket and DynamoDB table holding Terraform state
	terraform -chdir=terraform/bootstrap init -input=false
	terraform -chdir=terraform/bootstrap apply -auto-approve -input=false

nuke: ## Stop LocalStack and delete all emulated state
	docker compose down --remove-orphans
	rm -rf ./volume
