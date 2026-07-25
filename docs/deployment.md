# Deployment Guide

This guide deploys the platform into a real AWS account.

## 1. Bootstrap Identity

Create or choose an AWS IAM principal that can provision:

- VPC, subnets, route tables, endpoints, and security groups
- EKS clusters and managed node groups
- IAM roles and policies
- KMS keys
- S3 buckets and lifecycle policies
- Kinesis streams
- ECR repositories
- Glue Data Catalog databases
- CloudWatch log groups and dashboards
- SNS topics and subscriptions
- Secrets Manager secrets

For CI/CD, use GitHub OIDC and map the GitHub Actions role to this Terraform permission boundary.

## 2. Configure Terraform

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

After the first apply, write secret values into the generated secret ARNs:

```bash
aws secretsmanager put-secret-value \
  --secret-id data-platform/dev/snowflake \
  --secret-string '{"account":"...","user":"svc_dbt","password":"...","role":"TRANSFORMER_ROLE"}'
```

## 3. Build Images

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

make docker-build ENV=dev AWS_ACCOUNT_ID=<account>
make docker-push ENV=dev AWS_ACCOUNT_ID=<account>
```

## 4. Deploy to EKS

```bash
aws eks update-kubeconfig --name enterprise-data-platform-dev --region us-east-1
kubectl apply -k kubernetes/overlays/dev
kubectl get pods -n data-platform
```

Install managed add-ons that your organization requires before production rollout:

- AWS Load Balancer Controller
- Cluster Autoscaler or Karpenter
- External Secrets Operator or Secrets Store CSI Driver
- Spark Operator
- Prometheus Operator

The manifests in this repository are compatible with those add-ons but do not assume cluster-wide
operator installation has already happened.

## 5. Configure Snowflake and dbt

Run SQL in order:

```bash
snowsql -f snowflake/sql/001_create_foundation.sql
snowsql -f snowflake/sql/002_create_external_stages.sql
snowsql -f snowflake/sql/003_create_marts.sql
```

Then validate dbt:

```bash
cd dbt
dbt deps
dbt compile --profiles-dir .
dbt test --profiles-dir .
```

## 6. Register Metadata

Choose either DataHub or OpenMetadata.

For DataHub:

```bash
python metadata/datahub/emit_metadata.py --env dev
```

For OpenMetadata, import:

```text
metadata/openmetadata/ownership.yml
metadata/openmetadata/classifications.yml
```

## 7. Validate Observability

```bash
kubectl port-forward svc/prometheus-operated -n monitoring 9090:9090
kubectl port-forward svc/grafana -n monitoring 3000:80
python scripts/smoke_test.py --namespace data-platform --environment dev
```

Expected minimum checks:

- API `/healthz` returns healthy.
- Kafka consumer deployment has ready replicas.
- dbt runner CronJob exists.
- Prometheus alert rules load successfully.
- Airflow DAG import passes.

## Production Checklist

- Enable Terraform remote state with state locking.
- Enforce GitHub branch protection and manual approvals for prod.
- Set actual secret values in Secrets Manager.
- Enable AWS CloudTrail and EKS audit logging.
- Use private ingress or VPN for internal APIs.
- Set Snowflake resource monitors and alert thresholds.
- Enable OpenSearch index lifecycle management.
- Run disaster recovery restore tests at least quarterly.
