# Include variables from the .envrc file
include .envrc

# =================================================================================== #
# HELPERS #
# =================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

# =================================================================================== #
# DEVELOPMENT #
# =================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}

## db/psql: connect to the database using psql
.PHONY: db/sql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migration/new
db/migration/new:
	@echo 'Creating migration files for ${name}...'
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: confirm
	@echo 'Running up migrations...'
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# =================================================================================== #
# QUALITY CONTROL #
# =================================================================================== #
.PHONY: audit
audit:
	staticcheck -checks='-U1000' ./...

	@echo 'Tidying and verifying module dependencies...'
	go mod tidy             # Clean up and check dependencies
	go mod verify           # Verify the integrity of dependencies

	@echo 'Formatting code...'
	go fmt ./...            # Format all source code

	@echo 'Vetting code...'
	go vet ./...            # Static code analysis to detect potential issues
	staticcheck ./...       # Advanced static analysis with staticcheck

	@echo 'Running tests...'
	CGO_ENABLED=1 go test -race -vet=off ./...  # Run tests with race detection enabled, skipping go vet


