module "platform" {
  source = "../../modules/platform"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  cost_center                   = var.cost_center
  vpc_cidr                      = var.vpc_cidr
  availability_zones            = var.availability_zones
  private_subnets               = var.private_subnets
  public_subnets                = var.public_subnets
  domain_names                  = var.domain_names
  alert_email                   = var.alert_email
  eks_cluster_version           = var.eks_cluster_version
  eks_endpoint_public_access    = true
  eks_node_instance_types       = ["m6i.large"]
  spark_node_instance_types     = ["m6i.xlarge"]
  eks_min_size                  = 2
  eks_desired_size              = 2
  eks_max_size                  = 6
  enable_spot                   = true
  cloudwatch_log_retention_days = 14
  kinesis_retention_hours       = 48
  s3_noncurrent_expiration_days = 30
  enable_msk                    = var.enable_msk
  msk_instance_type             = "kafka.m5.large"
  msk_kafka_version             = "3.6.0"
}
