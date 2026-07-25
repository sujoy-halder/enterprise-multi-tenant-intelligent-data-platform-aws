data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  name             = "${var.project_name}-${var.environment}"
  account_id       = data.aws_caller_identity.current.account_id
  normalized_name  = lower(replace(local.name, "_", "-"))
  workload_sa_name = "data-platform-workload"
  namespace        = "data-platform"

  buckets = {
    lake      = "${local.normalized_name}-lake-${local.account_id}"
    artifacts = "${local.normalized_name}-artifacts-${local.account_id}"
    logs      = "${local.normalized_name}-logs-${local.account_id}"
  }

  ecr_repositories = toset([
    "api",
    "kafka-consumer",
    "dbt-runner",
    "spark"
  ])

  glue_layers = toset([
    "bronze",
    "silver",
    "gold",
    "marts"
  ])

  secrets = toset([
    "snowflake",
    "slack-webhook",
    "source-databases",
    "informatica"
  ])

  log_groups = toset([
    "airflow",
    "api",
    "consumers",
    "dbt",
    "spark"
  ])

  interface_endpoints = toset([
    "ecr.api",
    "ecr.dkr",
    "logs",
    "secretsmanager",
    "sts",
    "kinesis-streams",
    "glue"
  ])
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "prod"

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name}-vpc-endpoints"
  description = "Allow HTTPS from private subnets to interface VPC endpoints."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
}

resource "aws_kms_key" "platform" {
  description             = "KMS key for ${local.name} platform encryption."
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "platform" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.platform.key_id
}

resource "aws_s3_bucket" "platform" {
  for_each = local.buckets

  bucket        = each.value
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "platform" {
  for_each = aws_s3_bucket.platform

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "platform" {
  for_each = aws_s3_bucket.platform

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "platform" {
  for_each = aws_s3_bucket.platform

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.platform.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "platform" {
  for_each = aws_s3_bucket.platform

  bucket = each.value.id

  rule {
    id     = "cost-optimized-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_noncurrent_expiration_days
    }

    transition {
      days          = var.environment == "prod" ? 60 : 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.environment == "prod" ? 180 : 90
      storage_class = "GLACIER"
    }
  }
}

resource "aws_kinesis_stream" "domain_events" {
  for_each = toset(var.domain_names)

  name             = "${local.name}-${each.value}-events"
  retention_period = var.kinesis_retention_hours
  encryption_type  = "KMS"
  kms_key_id       = aws_kms_key.platform.arn

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

resource "aws_security_group" "msk" {
  count = var.enable_msk ? 1 : 0

  name        = "${local.name}-msk"
  description = "Allow Kafka clients inside the VPC to reach MSK."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "MSK IAM TLS from VPC"
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "msk" {
  count = var.enable_msk ? 1 : 0

  name              = "/aws/${local.name}/msk"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = aws_kms_key.platform.arn
}

resource "aws_msk_cluster" "platform" {
  count = var.enable_msk ? 1 : 0

  cluster_name           = "${local.name}-msk"
  kafka_version          = var.msk_kafka_version
  number_of_broker_nodes = length(module.vpc.private_subnets)

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = module.vpc.private_subnets
    security_groups = [aws_security_group.msk[0].id]

    storage_info {
      ebs_storage_info {
        volume_size = var.environment == "prod" ? 1000 : 100
      }
    }
  }

  client_authentication {
    sasl {
      iam = true
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.platform.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk[0].name
      }
    }
  }
}

resource "aws_ecr_repository" "workloads" {
  for_each = local.ecr_repositories

  name                 = "${local.name}-${each.value}"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.platform.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "workloads" {
  for_each = aws_ecr_repository.workloads

  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_glue_catalog_database" "layers" {
  for_each = local.glue_layers

  name        = replace("${var.environment}_${each.value}", "-", "_")
  description = "${each.value} layer for ${local.name}"
}

resource "aws_secretsmanager_secret" "platform" {
  for_each = local.secrets

  name        = "data-platform/${var.environment}/${each.value}"
  description = "Secret container for ${each.value} in ${local.name}."
  kms_key_id  = aws_kms_key.platform.arn
}

resource "aws_cloudwatch_log_group" "platform" {
  for_each = local.log_groups

  name              = "/aws/${local.name}/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = aws_kms_key.platform.arn
}

resource "aws_sns_topic" "alerts" {
  name              = "${local.name}-alerts"
  kms_master_key_id = aws_kms_key.platform.arn
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == "" ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "archive_file" "alert_router" {
  type        = "zip"
  source_file = "${path.module}/lambda_alert_router/index.py"
  output_path = "${path.module}/lambda_alert_router.zip"
}

resource "aws_iam_role" "alert_router" {
  name = "${local.name}-alert-router"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "alert_router" {
  name = "${local.name}-alert-router"
  role = aws_iam_role.alert_router.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

resource "aws_lambda_function" "alert_router" {
  function_name    = "${local.name}-alert-router"
  role             = aws_iam_role.alert_router.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.alert_router.output_path
  source_code_hash = data.archive_file.alert_router.output_base64sha256
  timeout          = 30
  kms_key_arn      = aws_kms_key.platform.arn

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_router.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "alert_router" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_router.arn
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = var.eks_endpoint_public_access
  enable_cluster_creator_admin_permissions = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    platform = {
      instance_types = var.eks_node_instance_types
      min_size       = var.eks_min_size
      max_size       = var.eks_max_size
      desired_size   = var.eks_desired_size
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "platform"
      }
    }

    spark = {
      instance_types = var.spark_node_instance_types
      min_size       = 0
      max_size       = var.eks_max_size
      desired_size   = var.environment == "prod" ? 1 : 0
      capacity_type  = var.enable_spot ? "SPOT" : "ON_DEMAND"

      labels = {
        workload = "spark"
      }
    }
  }
}

data "aws_iam_policy_document" "workload_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${local.namespace}:${local.workload_sa_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workload" {
  name               = "${local.name}-workload"
  assume_role_policy = data.aws_iam_policy_document.workload_assume_role.json
}

data "aws_iam_policy_document" "workload" {
  statement {
    sid = "LakeAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = flatten([
      for bucket in aws_s3_bucket.platform : [
        bucket.arn,
        "${bucket.arn}/*"
      ]
    ])
  }

  statement {
    sid = "StreamAccess"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = [for stream in aws_kinesis_stream.domain_events : stream.arn]
  }

  statement {
    sid = "KafkaIamAccess"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
      "kafka-cluster:CreateTopic",
      "kafka-cluster:DescribeTopic"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:kafka:${var.aws_region}:${local.account_id}:cluster/${local.name}-msk/*",
      "arn:${data.aws_partition.current.partition}:kafka:${var.aws_region}:${local.account_id}:topic/${local.name}-msk/*",
      "arn:${data.aws_partition.current.partition}:kafka:${var.aws_region}:${local.account_id}:group/${local.name}-msk/*"
    ]
  }

  statement {
    sid = "SecretsRead"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [for secret in aws_secretsmanager_secret.platform : secret.arn]
  }

  statement {
    sid = "GlueCatalog"
    actions = [
      "glue:CreateTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
      "glue:UpdateTable"
    ]
    resources = ["*"]
  }

  statement {
    sid = "KmsUse"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.platform.arn]
  }
}

resource "aws_iam_policy" "workload" {
  name        = "${local.name}-workload"
  description = "Least-privilege data platform workload access."
  policy      = data.aws_iam_policy_document.workload.json
}

resource "aws_iam_role_policy_attachment" "workload" {
  role       = aws_iam_role.workload.name
  policy_arn = aws_iam_policy.workload.arn
}

resource "aws_cloudwatch_dashboard" "platform" {
  dashboard_name = "${local.name}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Kinesis Incoming Records"
          region  = var.aws_region
          metrics = [for stream in aws_kinesis_stream.domain_events : ["AWS/Kinesis", "IncomingRecords", "StreamName", stream.name]]
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EKS API Server Requests"
          region  = var.aws_region
          metrics = [["AWS/EKS", "cluster_failed_request_count", "ClusterName", module.eks.cluster_name]]
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}
