output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "lake_bucket" {
  value = aws_s3_bucket.platform["lake"].bucket
}

output "artifact_bucket" {
  value = aws_s3_bucket.platform["artifacts"].bucket
}

output "log_bucket" {
  value = aws_s3_bucket.platform["logs"].bucket
}

output "kinesis_streams" {
  value = { for domain, stream in aws_kinesis_stream.domain_events : domain => stream.name }
}

output "ecr_repository_urls" {
  value = { for name, repo in aws_ecr_repository.workloads : name => repo.repository_url }
}

output "msk_bootstrap_brokers_sasl_iam" {
  value = var.enable_msk ? aws_msk_cluster.platform[0].bootstrap_brokers_sasl_iam : null
}

output "secret_arns" {
  value = { for name, secret in aws_secretsmanager_secret.platform : name => secret.arn }
}

output "kms_key_arn" {
  value = aws_kms_key.platform.arn
}

output "workload_role_arn" {
  value = aws_iam_role.workload.arn
}
