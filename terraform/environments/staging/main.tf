terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "vetrii-terraform-state-bucket"
    key            = "vetrii-backend/staging/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

variable "project_name" {
  description = "Project name used for tagging and naming"
  type        = string
  default     = "vetrii"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "staging"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create (defaults to project-environment-bucket)"
  type        = string
  default     = null
}

# variable "queue_email_name" {
#   description = "Name for the email queue (defaults to email-queue-<env>)"
#   type        = string
#   default     = "vetrii-email-queue-staging"
# }

# variable "queue_withdraw_usdc_name" {
#   description = "Name for the withdraw-usdc queue (defaults to withdraw-usdc-<env>)"
#   type        = string
#   default     = "vetrii-withdraw-usdc-staging"
# }

variable "tags_extra" {
  description = "Extra tags to add to resources"
  type        = map(string)
  default     = {}
}

locals {
  resolved_bucket_name      = coalesce(var.bucket_name, "${var.project_name}-${var.environment}-bucket")
  # resolved_email_queue_name = coalesce(var.queue_email_name, "vetrii-email-queue-${var.environment}")
  # resolved_withdraw_queue_name = coalesce(var.queue_withdraw_usdc_name, "vetrii-withdraw-usdc-${var.environment}")
  common_tags = merge({
    Project     = var.project_name,
    Environment = var.environment
  }, var.tags_extra)
}

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Comment     = "Managed by Terraform"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  alias   = "us_east_1"
  region  = "us-east-1"
}

module "s3_bucket" {
  source        = "../../modules/s3_bucket"
  bucket_name   = local.resolved_bucket_name
  versioning    = false
  force_destroy = false
  tags          = local.common_tags
}

# module "sqs_email_queue" {
#   source      = "../../modules/sqs_queue"
#   queue_name  = local.resolved_email_queue_name
#   dlq_enabled = true
#   dlq_name    = "vetrii-email-queue-dlq-${var.environment}"
#   tags        = local.common_tags
# }

# module "sqs_withdraw_usdc_queue" {
#   source      = "../../modules/sqs_queue"
#   queue_name  = local.resolved_withdraw_queue_name
#   dlq_enabled = true
#   dlq_name    = "vetrii-withdraw-usdc-dlq-${var.environment}"
#   tags        = local.common_tags
# }

############################
# IAM user for SQS access  #
############################

# resource "aws_iam_user" "sqs_user" {
#   name = "${var.project_name}-sqs-${var.environment}"
#   tags = local.common_tags
# }

# data "aws_iam_policy_document" "sqs_access" {
#   statement {
#     sid     = "AllowSQSActionsOnEnvQueues"
#     effect  = "Allow"
#     actions = [
#       "sqs:SendMessage",
#       "sqs:ReceiveMessage",
#       "sqs:DeleteMessage",
#       "sqs:ChangeMessageVisibility",
#       "sqs:GetQueueAttributes",
#       "sqs:PurgeQueue"
#     ]
#     resources = compact([
#       module.sqs_email_queue.queue_arn,
#       module.sqs_email_queue.dlq_arn,
#       module.sqs_withdraw_usdc_queue.queue_arn,
#       module.sqs_withdraw_usdc_queue.dlq_arn
#     ])
#   }
# }

# resource "aws_iam_user_policy" "sqs_access" {
#   name   = "${var.project_name}-sqs-access-${var.environment}"
#   user   = aws_iam_user.sqs_user.name
#   policy = data.aws_iam_policy_document.sqs_access.json
# }

# resource "aws_iam_access_key" "sqs_user" {
#   user = aws_iam_user.sqs_user.name
# }

###########################
# IAM user for S3 access  #
###########################

resource "aws_iam_user" "s3_user" {
  name = "${var.project_name}-s3-${var.environment}"
  tags = local.common_tags
}

resource "aws_iam_access_key" "s3_user" {
  user = aws_iam_user.s3_user.name
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    sid     = "AllowS3ActionsOnEnvBuckets"
    effect  = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketAttributes"
    ]
    resources = compact([
      module.s3_bucket.bucket_arn,
      "${module.s3_bucket.bucket_arn}/*"
    ])
  }
}

resource "aws_iam_user_policy" "s3_access" {
  name   = "${var.project_name}-sqs-access-${var.environment}"
  user   = aws_iam_user.s3_user.name
  policy = data.aws_iam_policy_document.s3_access.json
}

############
# Outputs  #
############

output "s3_bucket_name" {
  description = "Created S3 bucket name"
  value       = module.s3_bucket.bucket_name
}

output "s3_bucket_arn" {
  description = "Created S3 bucket ARN"
  value       = module.s3_bucket.bucket_arn
}

# output "sqs_email_queue_arn" {
#   description = "Created email SQS queue ARN"
#   value       = module.sqs_email_queue.queue_arn
# }

# output "sqs_withdraw_usdc_queue_arn" {
#   description = "Created withdraw-usdc SQS queue ARN"
#   value       = module.sqs_withdraw_usdc_queue.queue_arn
# }

# output "sqs_iam_user_name" {
#   description = "IAM user for SQS access"
#   value       = aws_iam_user.sqs_user.name
# }

# output "sqs_access_key_id" {
#   description = "Access key ID for the SQS IAM user"
#   value       = aws_iam_access_key.sqs_user.id
#   sensitive   = true
# }

# output "sqs_secret_access_key" {
#   description = "Secret access key for the SQS IAM user"
#   value       = aws_iam_access_key.sqs_user.secret
#   sensitive   = true
# }

output "s3_iam_user_name" {
  description = "IAM user for S3 access"
  value       = aws_iam_user.s3_user.name
}

output "s3_access_key_id" {
  description = "Access key ID for the S3 IAM user"
  value       = aws_iam_access_key.s3_user.id
  sensitive   = true
}

output "s3_secret_access_key" {
  description = "Secret access key for the S3 IAM user"
  value       = aws_iam_access_key.s3_user.secret
  sensitive   = true
}
