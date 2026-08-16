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
TTL_HOURS ?= 24

.PHONY: help up down logs health test-unit test smoke fmt validate bootstrap shared env-up env-down env-url env-logs env-list reap reap-force nuke

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

env-up: ## Create or update the preview environment for PR=<n> [REF=<branch>]
	@test -n "$(PR)" || { echo "usage: make env-up PR=<number> [REF=<branch>] [COMMIT=<sha>]"; exit 1; }
	@PR=$(PR) COMMIT=$(COMMIT) REF=$(REF) PREVIEW_DIR=$(PREVIEW_DIR) PUBLIC_PORT=$(LOCALSTACK_PORT) \
		./scripts/env-up.sh
	@$(MAKE) --no-print-directory env-url PR=$(PR)

env-down: ## Destroy the preview environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-down PR=<number>"; exit 1; }
	@terraform -chdir=$(PREVIEW_DIR) init -input=false >/dev/null
	@if terraform -chdir=$(PREVIEW_DIR) workspace select pr-$(PR) >/dev/null 2>&1; then \
		terraform -chdir=$(PREVIEW_DIR) destroy -auto-approve -input=false -var pr_number=$(PR); \
		terraform -chdir=$(PREVIEW_DIR) workspace select default >/dev/null; \
		terraform -chdir=$(PREVIEW_DIR) workspace delete pr-$(PR); \
		git worktree remove --force .worktrees/pr-$(PR) 2>/dev/null || true; \
	else \
		echo "environment pr-$(PR) does not exist"; \
	fi

env-url: ## Print the URLs of the preview environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-url PR=<number>"; exit 1; }
	@terraform -chdir=$(PREVIEW_DIR) workspace select pr-$(PR) >/dev/null
	@echo "api:  $$(terraform -chdir=$(PREVIEW_DIR) output -raw api_url)"
	@echo "site: http://$$(terraform -chdir=$(PREVIEW_DIR) output -raw site_bucket).s3-website.localhost.localstack.cloud:$(LOCALSTACK_PORT)"

env-logs: ## Follow application logs of the environment for PR=<n>
	@test -n "$(PR)" || { echo "usage: make env-logs PR=<number>"; exit 1; }
	aws logs tail /aws/lambda/pr-$(PR)-api --since 10m --follow

env-list: ## List live preview environments
	@terraform -chdir=$(PREVIEW_DIR) workspace list \
		| sed 's/^[* ] *//' | grep '^pr-' || echo "no preview environments"

reap: ## Show which preview environments are stale
	@PREVIEW_DIR=$(PREVIEW_DIR) TTL_HOURS=$(TTL_HOURS) ./scripts/reap.sh

reap-force: ## Destroy stale preview environments
	@PREVIEW_DIR=$(PREVIEW_DIR) TTL_HOURS=$(TTL_HOURS) FORCE=1 ./scripts/reap.sh

nuke: ## Stop LocalStack and delete all emulated state
	docker compose down --remove-orphans
	rm -rf ./volume
