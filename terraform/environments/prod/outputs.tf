output "cluster_name" {
  value = module.platform.cluster_name
}

output "vpc_id" {
  value = module.platform.vpc_id
}

output "lake_bucket" {
  value = module.platform.lake_bucket
}

output "artifact_bucket" {
  value = module.platform.artifact_bucket
}

output "kinesis_streams" {
  value = module.platform.kinesis_streams
}

output "ecr_repository_urls" {
  value = module.platform.ecr_repository_urls
}

output "workload_role_arn" {
  value = module.platform.workload_role_arn
}

output "msk_bootstrap_brokers_sasl_iam" {
  value = module.platform.msk_bootstrap_brokers_sasl_iam
}

output "secret_arns" {
  value     = module.platform.secret_arns
  sensitive = true
}
