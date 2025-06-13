.PHONY: help install test test-verbose coverage lint format console clean ci setup

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initial setup - install dependencies
	bundle install

install: ## Install dependencies
	bundle install

test: ## Run all tests
	bundle exec rspec

test-verbose: ## Run tests with verbose output
	bundle exec rspec --format documentation

coverage: ## Run tests with coverage report
	bundle exec rake coverage

lint: ## Run linting (RuboCop)
	bundle exec rubocop

format: ## Auto-fix linting issues
	bundle exec rubocop -a

console: ## Start interactive console
	bundle exec rake console

clean: ## Clean up generated files
	rm -rf coverage/
	rm -f .rspec_status

ci: ## Run CI pipeline (tests + linting)
	bundle exec rake ci

build: ## Build the gem
	bundle exec rake build

release: ## Release the gem (requires proper credentials)
	bundle exec rake release

yard: ## Generate documentation
	bundle exec yard

server: ## Start YARD documentation server
	bundle exec yard server

# Development shortcuts
t: test ## Shortcut for test
l: lint ## Shortcut for lint
c: console ## Shortcut for console 