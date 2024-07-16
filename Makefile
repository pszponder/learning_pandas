.ONESHELL:

# Define variables
VENV := .venv
BIN := $(VENV)/bin
PIP := $(BIN)/pip
PYTHON := $(BIN)/python
ACTIVATE := . ./$(BIN)/activate
APP := src/main.py
DOCKER_TAG := project_name # Change to your project name

# Define default target
.DEFAULT_GOAL := help

# ================================================
# HELPERS
# ================================================

# Default target
.PHONY: help
help: ## List available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-15s - %s\n", $$1, $$2}'

# ================================================
# Startup
# ================================================

# Target to create virtual environment
.PHONY: venv
venv: ## Create a virtual environment
	python -m venv .venv
	@echo "To activate virtual env => source .venv/bin/activate"

# Target to install dependencies
.PHONY: install
install: venv ## Install dependencies
	$(PIP) install -U -r requirements.txt

.PHONY: init
init: venv install ## Initialize python project (runs make venv & make install)

# ================================================
# RUNNING
# ================================================

.PHONY: run
run: ## Run the project
	$(PYTHON) $(APP)

# ================================================
# CLEANING
# ================================================

.PHONY: clean
clean: ## Remove all temporary files
	rm -rf .ruff_cache
	rm -rf .pytest_cache
	find . -type f -name *.pyc -delete
	find . -type d -name __pycache__ -delete

.PHONY: cleanall
cleanall: clean ## Remove all temporary files and virtual environment
	rm -rf $(VENV)

# ================================================
# QUALITY CONTROL
# ================================================

.PHONY: lint
lint: ## Lint code using ruff linter
	$(BIN)/ruff check

.PHONY: format
format: ## Formats code using ruff formatter
	$(BIN)/ruff format

.PHONY: tidy
tidy: lint format ## Lint & format code

# ================================================
# DEPENDENCIES and PACKAGES
# ================================================

.PHONY: update
update: ## Update requirements.txt with all installed python packages in venv
	$(PIP) freeze > requirements.txt

.PHONY: add
add: ## Add python package(s) to requirements.txt
	$(PIP) install $(filter-out $@,$(MAKECMDGOALS))
	$(PIP) freeze > requirements.txt

.PHONY: remove
remove: ## Remove python package(s) from requirements.txt
	$(PIP) uninstall $(filter-out $@,$(MAKECMDGOALS))
	$(PIP) freeze > requirements.txt

.PHONY: upgrade
upgrade: ## Upgrade python package(s) in requirements.txt to latest version
	sed -i 's/[~=]=/>=/' requirements.txt
	$(PIP) install -U -r requirements.txt
	$(PIP) freeze > requirements.txt

# ================================================
# DOCKER
# ================================================

.PHONY: build
build: ## Build docker image
	docker build -t $(DOCKER_TAG) .

.PHONY: up
up: ## Run docker container
	docker compose up -d

.PHONY: upbuild
upbuild: build up ## Build and run docker container

.PHONY: restart
restart: ## Restart docker container
	docker compose restart

.PHONY: logs
logs: ## View docker container logs
	docker compose logs

.PHONY: logsf
logsf: ## View docker container logs in real time
	docker compose logs -f app --tail=100

.PHONY: dclean
dclean: ## Remove docker container
	docker rm -f $(DOCKER_TAG)

.PHONY: down
down: ## Stop docker container
	docker compose down

.PHONY: downall
downall: dclean ## Stop and remove docker container
	docker compose down -v --remove-orphans --rmi all