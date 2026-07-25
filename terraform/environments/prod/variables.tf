variable "project_name" {
  description = "Platform project name."
  type        = string
  default     = "enterprise-data-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "cost_center" {
  description = "Cost allocation tag."
  type        = string
  default     = "data-platform"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.50.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs."
  type        = list(string)
  default     = ["10.50.10.0/23", "10.50.12.0/23", "10.50.14.0/23"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs for load balancers and NAT."
  type        = list(string)
  default     = ["10.50.100.0/24", "10.50.101.0/24", "10.50.102.0/24"]
}

variable "domain_names" {
  description = "Business domains supported by the shared platform."
  type        = list(string)
  default     = ["retail", "healthcare", "finance", "logistics"]
}

variable "alert_email" {
  description = "Optional email subscription for SNS alerts."
  type        = string
  default     = ""
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "enable_msk" {
  description = "Provision Amazon MSK for Apache Kafka."
  type        = bool
  default     = true
}
