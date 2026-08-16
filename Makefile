-include .env

LOCALSTACK_PORT ?= 4566
LOCALSTACK_ENDPOINT ?= http://localhost:$(LOCALSTACK_PORT)

AWS_ENDPOINT_URL ?= $(LOCALSTACK_ENDPOINT)
AWS_ACCESS_KEY_ID ?= test
AWS_SECRET_ACCESS_KEY ?= test
AWS_DEFAULT_REGION ?= us-east-1
export AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

PREVIEW_DIR := terraform/envs/preview
COMMIT ?= unknown

.PHONY: help up down logs health test-unit test smoke fmt validate bootstrap shared env-up env-down env-url env-list nuke

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

test-unit: ## Run application unit tests
	python3 -m unittest discover app/api

test: test-unit ## Run unit tests and Terraform tests
	terraform -chdir=$(PREVIEW_DIR) init -input=false
	terraform -chdir=$(PREVIEW_DIR) test

smoke: ## Run HTTP smoke tests against the environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make smoke PR=<number> [COMMIT=<sha>]"; exit 1; }
	@terraform -chdir=$(PREVIEW_DIR) workspace select pr-$(PR) >/dev/null
	@API_URL="$$(terraform -chdir=$(PREVIEW_DIR) output -raw api_url)" \
		SITE_URL="http://$$(terraform -chdir=$(PREVIEW_DIR) output -raw site_bucket).s3-website.localhost.localstack.cloud:$(LOCALSTACK_PORT)" \
		PR_NUMBER="$(PR)" COMMIT_SHA="$(COMMIT)" \
		./scripts/smoke.sh

fmt: ## Format Terraform files
	terraform fmt -recursive terraform

validate: ## Check formatting and validate every Terraform configuration
	terraform fmt -check -recursive terraform
	@for dir in $$(find terraform -name '*.tf' -exec dirname {} \; | sort -u); do \
		echo "==> $$dir"; \
		terraform -chdir="$$dir" init -backend=false -input=false >/dev/null || exit 1; \
		terraform -chdir="$$dir" validate || exit 1; \
	done

bootstrap: ## Create the S3 bucket and DynamoDB table holding Terraform state
	terraform -chdir=terraform/bootstrap init -input=false
	terraform -chdir=terraform/bootstrap apply -auto-approve -input=false

shared: ## Create long-lived resources shared by every environment
	terraform -chdir=terraform/shared init -input=false
	terraform -chdir=terraform/shared apply -auto-approve -input=false

env-up: ## Create or update the preview environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-up PR=<number> [COMMIT=<sha>]"; exit 1; }
	terraform -chdir=$(PREVIEW_DIR) init -input=false
	terraform -chdir=$(PREVIEW_DIR) workspace select -or-create pr-$(PR)
	terraform -chdir=$(PREVIEW_DIR) apply -auto-approve -input=false \
		-var pr_number=$(PR) -var commit_sha=$(COMMIT) -var public_port=$(LOCALSTACK_PORT)
	@$(MAKE) --no-print-directory env-url PR=$(PR)

env-down: ## Destroy the preview environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-down PR=<number>"; exit 1; }
	@terraform -chdir=$(PREVIEW_DIR) init -input=false >/dev/null
	@if terraform -chdir=$(PREVIEW_DIR) workspace select pr-$(PR) >/dev/null 2>&1; then \
		terraform -chdir=$(PREVIEW_DIR) destroy -auto-approve -input=false -var pr_number=$(PR); \
		terraform -chdir=$(PREVIEW_DIR) workspace select default >/dev/null; \
		terraform -chdir=$(PREVIEW_DIR) workspace delete pr-$(PR); \
	else \
		echo "environment pr-$(PR) does not exist"; \
	fi

env-url: ## Print the URLs of the preview environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-url PR=<number>"; exit 1; }
	@terraform -chdir=$(PREVIEW_DIR) workspace select pr-$(PR) >/dev/null
	@echo "api:  $$(terraform -chdir=$(PREVIEW_DIR) output -raw api_url)"
	@echo "site: http://$$(terraform -chdir=$(PREVIEW_DIR) output -raw site_bucket).s3-website.localhost.localstack.cloud:$(LOCALSTACK_PORT)"

env-list: ## List live preview environments
	@terraform -chdir=$(PREVIEW_DIR) workspace list

nuke: ## Stop LocalStack and delete all emulated state
	docker compose down --remove-orphans
	rm -rf ./volume
