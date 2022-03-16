.PHONY: build push
.DEFAULT_GOAL := help

build: ## Build Docker image
	docker build -t ernestas/deploy:latest -t ernestas/deploy:$(shell git rev-parse HEAD) .
	docker scan --severity high --accept-license -f Dockerfile ernestas/deploy:$(shell git rev-parse HEAD)

push: ## Push Docker image
	docker push ernestas/deploy:$(shell git rev-parse HEAD)
	docker push ernestas/deploy:latest

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
