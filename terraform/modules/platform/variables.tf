variable "project_name" {
  description = "Platform project name."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "cost_center" {
  description = "Cost allocation tag."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones."
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "domain_names" {
  description = "Business domains."
  type        = list(string)
}

variable "alert_email" {
  description = "Optional SNS email subscription."
  type        = string
  default     = ""
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS."
  type        = string
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly reachable."
  type        = bool
  default     = false
}

variable "eks_node_instance_types" {
  description = "EKS platform node instance types."
  type        = list(string)
}

variable "spark_node_instance_types" {
  description = "Spark node instance types."
  type        = list(string)
}

variable "eks_min_size" {
  description = "Minimum node group size."
  type        = number
}

variable "eks_desired_size" {
  description = "Desired node group size."
  type        = number
}

variable "eks_max_size" {
  description = "Maximum node group size."
  type        = number
}

variable "enable_spot" {
  description = "Use spot capacity for bursty workloads where safe."
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "kinesis_retention_hours" {
  description = "Kinesis retention period in hours."
  type        = number
  default     = 48
}

variable "s3_noncurrent_expiration_days" {
  description = "Days to keep noncurrent S3 versions."
  type        = number
  default     = 30
}

variable "enable_msk" {
  description = "Provision Amazon MSK for Apache Kafka."
  type        = bool
  default     = false
}

variable "msk_instance_type" {
  description = "MSK broker instance type."
  type        = string
  default     = "kafka.m5.large"
}

variable "msk_kafka_version" {
  description = "Kafka version for MSK."
  type        = string
  default     = "3.6.0"
}
