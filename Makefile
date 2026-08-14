-include .env

LOCALSTACK_PORT ?= 4566
LOCALSTACK_ENDPOINT ?= http://localhost:$(LOCALSTACK_PORT)

.PHONY: help up down logs health nuke

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

nuke: ## Stop LocalStack and delete all emulated state
	docker compose down --remove-orphans
	rm -rf ./volume
