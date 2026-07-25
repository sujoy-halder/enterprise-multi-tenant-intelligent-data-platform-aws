# Enterprise Multi-Tenant Intelligent Data Platform on AWS

This repository is a deployment-ready reference implementation for a shared enterprise data
platform that ingests, processes, governs, monitors, and serves data across Retail, Healthcare,
Finance, and Logistics domains.

It is intentionally structured like an internal platform team repository rather than a single
pipeline demo. The code includes AWS infrastructure, Kubernetes workloads, CI/CD, Airflow DAGs,
Spark jobs, dbt models, Snowflake setup scripts, Great Expectations suites, metadata emitters,
monitoring assets, and operational runbooks.

## Platform Capabilities

- Multi-domain ingestion for events, APIs, CSV uploads, CDC, databases, and IoT telemetry.
- Real-time streaming through Amazon Kinesis and Kafka-compatible consumers.
- Medallion lakehouse layout on S3: bronze, silver, and gold.
- Batch and streaming processing with Spark and Databricks job definitions.
- Business marts in Snowflake for Finance, Sales, Supply Chain, Customer Analytics, and Executive reporting.
- dbt models, tests, documentation, and lineage-friendly YAML.
- Great Expectations checks for nulls, duplicates, schema drift, ranges, freshness, and referential integrity.
- EKS deployments for APIs, Kafka consumers, Spark jobs, dbt runner, and platform services.
- Airflow orchestration with production-style DAGs and alert hooks.
- Observability with Prometheus, Grafana, CloudWatch, OpenSearch, and SNS.
- Governance with DataHub/OpenMetadata ownership, classifications, and PII tagging examples.
- Security by default: private subnets, IAM least privilege, KMS, Secrets Manager, RBAC, and audit logging.
- Cost controls: S3 lifecycle policies, autoscaling, spot node groups, Snowflake warehouse sizing, and dashboards.

## Repository Map

```text
enterprise-data-platform/
  terraform/       AWS network, EKS, S3, Kinesis, ECR, Glue, CloudWatch, SNS, Secrets Manager
  kubernetes/      Kustomize manifests for platform workloads and production controls
  docker/          Images for API, Kafka consumer, dbt runner, and Spark runtime
  airflow/         DAGs for streaming health, batch ingestion, CDC, dbt, and data quality
  spark/           PySpark jobs for bronze, silver, and gold transformations
  databricks/      Databricks workflow definitions and notebook-style jobs
  dbt/             Snowflake dbt project with facts, dimensions, marts, docs, and tests
  snowflake/       SQL setup for warehouses, databases, roles, grants, stages, and tasks
  quality/         Great Expectations configuration and expectation suites
  monitoring/      Prometheus rules, Grafana dashboards, CloudWatch dashboard notes
  metadata/        DataHub and OpenMetadata bootstrap assets
  security/        IAM/RBAC/key policy examples and threat model
  docs/            Deployment guide, runbooks, governance, and cost optimization
```

## Prerequisites

- AWS account with permission to create VPC, EKS, ECR, IAM, KMS, S3, Kinesis, Glue, CloudWatch, SNS, and Secrets Manager resources.
- Terraform 1.6 or newer.
- kubectl and access to the generated EKS cluster.
- Docker with BuildKit enabled.
- Python 3.11 or newer.
- Snowflake account for dbt and marts.
- Optional but recommended: Databricks workspace, Slack webhook, DataHub or OpenMetadata instance.

## Quick Start

1. Copy `.env.example` to `.env` and fill in account-specific values.
2. Configure Terraform variables:

   ```bash
   cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
   ```

3. Provision AWS infrastructure:

   ```bash
   make terraform-init ENV=dev
   make terraform-plan ENV=dev
   cd terraform/environments/dev && terraform apply tfplan
   ```

4. Build and push runtime images:

   ```bash
   make docker-build ENV=dev AWS_ACCOUNT_ID=<account-id>
   make docker-push ENV=dev AWS_ACCOUNT_ID=<account-id>
   ```

5. Deploy workloads to EKS:

   ```bash
   aws eks update-kubeconfig --name enterprise-data-platform-dev --region us-east-1
   make k8s-apply ENV=dev
   ```

6. Run data quality, dbt, and smoke tests:

   ```bash
   make dbt-test
   make smoke ENV=dev
   ```

## Deployment Environments

The repository includes `dev` and `prod` overlays. Use dev for demos and interviews, and prod for
real deployments with stricter node sizing, higher replica counts, and reduced public access.

Key differences:

- Dev uses smaller node groups and shorter retention periods.
- Prod enables stronger retention, more replicas, stricter disruption budgets, and hardened network policy defaults.
- Both environments are configured through Terraform variables and Kubernetes Kustomize overlays.

## Security Notes

No static secret values are stored in the repository. Terraform creates secret containers in AWS
Secrets Manager, and workloads access them through IAM roles for service accounts. Fill secret
values after Terraform apply by using the AWS console, AWS CLI, or your enterprise secret pipeline.

## Interview Narrative

This project demonstrates senior data engineering capability because it covers the real platform
surface area: infrastructure as code, streaming, CDC, batch processing, orchestration, governance,
security, observability, quality gates, cost controls, and production deployment workflows.

Use `docs/deployment.md` for the operational walkthrough and `architecture/platform.mmd` for the
architecture diagram.
