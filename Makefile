SHELL := /bin/bash

PROJECT ?= enterprise-data-platform
ENV ?= dev
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= 000000000000
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

.PHONY: help
help:
	@echo "Targets:"
	@echo "  lint                 Run local static checks"
	@echo "  test                 Run unit tests"
	@echo "  terraform-init       Initialize Terraform for ENV=$(ENV)"
	@echo "  terraform-plan       Plan AWS infrastructure"
	@echo "  docker-build         Build deployable images"
	@echo "  k8s-apply            Apply Kubernetes overlay"
	@echo "  dbt-test             Run dbt compile and tests"
	@echo "  smoke                Run post-deploy smoke checks"

.PHONY: lint
lint:
	python -m compileall docker spark airflow scripts tests
	python scripts/validate_project.py

.PHONY: test
test:
	pytest -q

.PHONY: terraform-init
terraform-init:
	cd terraform/environments/$(ENV) && terraform init

.PHONY: terraform-plan
terraform-plan:
	cd terraform/environments/$(ENV) && terraform validate && terraform plan -out=tfplan

.PHONY: docker-build
docker-build:
	docker build -f docker/api/Dockerfile -t $(ECR_REGISTRY)/$(PROJECT)-api:$(ENV) docker/api
	docker build -f docker/consumer/Dockerfile -t $(ECR_REGISTRY)/$(PROJECT)-kafka-consumer:$(ENV) docker/consumer
	docker build -f docker/dbt/Dockerfile -t $(ECR_REGISTRY)/$(PROJECT)-dbt-runner:$(ENV) .
	docker build -f docker/spark/Dockerfile -t $(ECR_REGISTRY)/$(PROJECT)-spark:$(ENV) .

.PHONY: docker-push
docker-push:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)
	docker push $(ECR_REGISTRY)/$(PROJECT)-api:$(ENV)
	docker push $(ECR_REGISTRY)/$(PROJECT)-kafka-consumer:$(ENV)
	docker push $(ECR_REGISTRY)/$(PROJECT)-dbt-runner:$(ENV)
	docker push $(ECR_REGISTRY)/$(PROJECT)-spark:$(ENV)

.PHONY: k8s-apply
k8s-apply:
	kubectl apply -k kubernetes/overlays/$(ENV)

.PHONY: dbt-test
dbt-test:
	cd dbt && dbt deps && dbt compile --profiles-dir . && dbt test --profiles-dir .

.PHONY: smoke
smoke:
	python scripts/smoke_test.py --namespace data-platform --environment $(ENV)
