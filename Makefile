#!/usr/bin/make

SHELL = /bin/sh
DC_RUN_ARGS = --rm --user "$(shell id -u):$(shell id -g)"
CURRENT_USER = APP_UID=$(shell id -u) APP_GID=$(shell id -g)
FRONTEND_CONTAINER = web # remove for disable frontend build

.PHONY : help install composer-install npm-install dependencies-install ssh setup test start stop restart
.DEFAULT_GOAL : help

# This will output the help for each task. thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: env build dependencies-install start setup restart ## Install app

composer-install: ## Install web dependencies
	docker-compose run $(DC_RUN_ARGS) --no-deps app composer install --ansi --prefer-dist

npm-install: ## Install node dependencies
	docker-compose run $(DC_RUN_ARGS) --no-deps ${FRONTEND_CONTAINER} npm install

dependencies-install: ## Install app dependencies
	make composer-install
	-make npm-install

setup: ## Make full application initialization
	docker-compose run $(DC_RUN_ARGS) app php artisan key:generate --ansi
	docker-compose run $(DC_RUN_ARGS) app php artisan migrate --force --seed
	-docker-compose run $(DC_RUN_ARGS) --no-deps app php artisan storage:link --force

ssh: ## Start shell into app container
	docker-compose run $(DC_RUN_ARGS) app sh

node: ## Start shell into node container
	docker-compose run $(DC_RUN_ARGS) web sh

test: ## Execute app tests
	docker-compose run $(DC_RUN_ARGS) app composer test

build: ## Build php images
	$(CURRENT_USER) docker-compose build app nginx ${FRONTEND_CONTAINER}
	$(CURRENT_USER) docker-compose build api queue cron

start: ## Create and start containers
	docker-compose up --detach --remove-orphans nginx api queue cron ${FRONTEND_CONTAINER}
	@printf "\n   \e[30;42m %s \033[0m\n\n" 'Navigate your browser to ⇒ https://localhost';

stop: ## Stop containers
	docker-compose down

env: ## Copy env file
	cp -n .env.example .env
	cp -n api/.env.example api/.env
	cp -n web/.env.example web/.env

restart: stop start ## Restart all containers
