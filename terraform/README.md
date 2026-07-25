# Terraform

Terraform provisions the AWS platform foundation:

- VPC with public/private subnets and VPC endpoints.
- EKS cluster and managed node groups.
- KMS key for platform encryption.
- S3 lake, artifact, and log buckets with lifecycle rules.
- Kinesis streams per business domain.
- ECR repositories for deployable workloads.
- Glue Data Catalog databases for bronze, silver, gold, and marts.
- CloudWatch log groups and dashboard.
- SNS alerts and an alert-router Lambda.
- Secrets Manager secret containers.
- IAM role for Kubernetes service accounts through EKS OIDC.

Use `terraform/environments/dev` for sandbox deployments and `terraform/environments/prod` for
production-style settings.
