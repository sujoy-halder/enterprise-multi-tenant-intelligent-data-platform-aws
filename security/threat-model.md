# Threat Model

## Assets

- Raw and curated S3 data.
- Snowflake business marts.
- Secrets Manager credentials.
- KMS keys.
- Metadata catalog ownership and classifications.
- CI/CD deployment credentials.

## Primary Risks

- Cross-tenant data leakage between business domains.
- Overprivileged IAM roles.
- Secrets exposed through logs or container environment dumps.
- Public access to private APIs or buckets.
- Data quality failures reaching executive reports.
- Cost runaway from Spark, Kinesis, or Snowflake.

## Controls

- IAM least privilege and IRSA for Kubernetes workloads.
- KMS encryption for S3, Kinesis, ECR, logs, and secrets.
- Private subnets and VPC endpoints.
- Kubernetes NetworkPolicies and PodSecurity settings.
- dbt and Great Expectations quality gates in CI/CD.
- CloudWatch, Prometheus, Grafana, SNS, Slack, and email alerting.
- Snowflake resource monitors and warehouse auto-suspend.
- Metadata ownership and PII/PHI/PCI classifications.
